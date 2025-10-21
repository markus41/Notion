/**
 * Create GitHub Repository Activity Function
 *
 * Establishes automated repository creation and code deployment to GitHub,
 * streamlining version control initialization for autonomous build workflows.
 *
 * This solution is designed to support scalable development practices where
 * infrastructure and code repositories are provisioned programmatically with
 * proper branch protection, CI/CD workflows, and organizational standards.
 *
 * Best for: Organizations managing multiple repositories requiring consistent
 * configuration and automated deployment processes.
 */

const { Octokit } = require('@octokit/rest');
const axios = require('axios');

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Created repository details
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const { buildName, generatedFiles, description, isPrivate = true } = input;

  context.log('Creating GitHub repository', {
    buildName,
    fileCount: generatedFiles?.length || 0,
    isPrivate
  });

  try {
    // Initialize GitHub API client
    const octokit = new Octokit({
      auth: process.env.GITHUB_PERSONAL_ACCESS_TOKEN
    });

    const org = process.env.GITHUB_ORG || 'brookside-bi';
    const repoName = sanitizeRepoName(buildName);

    // Check if repository already exists
    const existingRepo = await checkRepositoryExists(octokit, org, repoName, context);
    if (existingRepo) {
      context.log.warn('Repository already exists', { repoName });
      return {
        success: true,
        repositoryUrl: existingRepo.html_url,
        cloneUrl: existingRepo.clone_url,
        alreadyExists: true
      };
    }

    // Create repository
    const repository = await createRepository(octokit, org, repoName, description, isPrivate, context);

    // Wait for repository to be fully initialized
    await sleep(2000);

    // Push generated files to repository
    if (generatedFiles && generatedFiles.length > 0) {
      await pushFilesToRepository(octokit, org, repoName, generatedFiles, context);
    }

    // Configure branch protection
    await configureBranchProtection(octokit, org, repoName, context);

    // Add repository topics/tags
    await addRepositoryTopics(octokit, org, repoName, context);

    context.log('GitHub repository created successfully', {
      repoName,
      repositoryUrl: repository.html_url,
      filesPushed: generatedFiles?.length || 0
    });

    return {
      success: true,
      repositoryUrl: repository.html_url,
      cloneUrl: repository.clone_url,
      sshUrl: repository.ssh_url,
      repoName,
      org,
      defaultBranch: repository.default_branch,
      filesPushed: generatedFiles?.length || 0
    };

  } catch (error) {
    context.log.error('Failed to create GitHub repository', {
      error: error.message,
      stack: error.stack,
      buildName
    });

    return {
      success: false,
      error: error.message,
      buildName
    };
  }
};

/**
 * Sanitize Repository Name
 *
 * Converts build name to valid GitHub repository name format.
 *
 * @param {string} buildName - Original build name
 * @returns {string} Sanitized repository name
 */
function sanitizeRepoName(buildName) {
  return buildName
    .toLowerCase()
    .replace(/[^a-z0-9-_.]/g, '-')  // Replace invalid chars with hyphen
    .replace(/--+/g, '-')            // Replace multiple hyphens with single
    .replace(/^-|-$/g, '')           // Remove leading/trailing hyphens
    .substring(0, 100);              // GitHub max length
}

/**
 * Check Repository Exists
 *
 * Verifies if repository already exists in organization.
 *
 * @param {Octokit} octokit - GitHub API client
 * @param {string} org - Organization name
 * @param {string} repoName - Repository name
 * @param {object} context - Function context
 * @returns {object|null} Repository object if exists, null otherwise
 */
async function checkRepositoryExists(octokit, org, repoName, context) {
  try {
    const { data } = await octokit.repos.get({
      owner: org,
      repo: repoName
    });
    return data;
  } catch (error) {
    if (error.status === 404) {
      return null; // Repository doesn't exist
    }
    throw error; // Other errors should propagate
  }
}

/**
 * Create Repository
 *
 * Establishes new repository in GitHub organization with proper configuration.
 *
 * @param {Octokit} octokit - GitHub API client
 * @param {string} org - Organization name
 * @param {string} repoName - Repository name
 * @param {string} description - Repository description
 * @param {boolean} isPrivate - Private repository flag
 * @param {object} context - Function context
 * @returns {object} Created repository object
 */
async function createRepository(octokit, org, repoName, description, isPrivate, context) {
  context.log('Creating repository in organization', { org, repoName });

  const { data } = await octokit.repos.createInOrg({
    org,
    name: repoName,
    description: description || `${repoName} - Autonomous Platform Build`,
    private: isPrivate,
    auto_init: true,  // Initialize with README
    gitignore_template: 'Node',  // Will be overwritten by generated .gitignore
    has_issues: true,
    has_projects: true,
    has_wiki: false,
    allow_squash_merge: true,
    allow_merge_commit: true,
    allow_rebase_merge: true,
    delete_branch_on_merge: true
  });

  return data;
}

/**
 * Push Files to Repository
 *
 * Commits and pushes generated files to repository using GitHub API.
 *
 * @param {Octokit} octokit - GitHub API client
 * @param {string} org - Organization name
 * @param {string} repoName - Repository name
 * @param {Array} files - Generated files array
 * @param {object} context - Function context
 */
async function pushFilesToRepository(octokit, org, repoName, files, context) {
  context.log('Pushing files to repository', {
    org,
    repoName,
    fileCount: files.length
  });

  // Get default branch
  const { data: repo } = await octokit.repos.get({
    owner: org,
    repo: repoName
  });
  const defaultBranch = repo.default_branch || 'main';

  // Get current commit SHA
  const { data: ref } = await octokit.git.getRef({
    owner: org,
    repo: repoName,
    ref: `heads/${defaultBranch}`
  });
  const currentCommitSha = ref.object.sha;

  // Get current tree
  const { data: currentCommit } = await octokit.git.getCommit({
    owner: org,
    repo: repoName,
    commit_sha: currentCommitSha
  });
  const currentTreeSha = currentCommit.tree.sha;

  // Create blobs for all files
  const tree = await Promise.all(
    files.map(async (file) => {
      const { data: blob } = await octokit.git.createBlob({
        owner: org,
        repo: repoName,
        content: Buffer.from(file.content).toString('base64'),
        encoding: 'base64'
      });

      return {
        path: file.path,
        mode: '100644',  // Regular file
        type: 'blob',
        sha: blob.sha
      };
    })
  );

  // Create new tree
  const { data: newTree } = await octokit.git.createTree({
    owner: org,
    repo: repoName,
    base_tree: currentTreeSha,
    tree
  });

  // Create commit
  const { data: newCommit } = await octokit.git.createCommit({
    owner: org,
    repo: repoName,
    message: `feat: Initialize codebase with ${files.length} generated files\n\n🤖 Generated with Claude Code (https://claude.com/claude-code)\n\nCo-Authored-By: Claude <noreply@anthropic.com>`,
    tree: newTree.sha,
    parents: [currentCommitSha]
  });

  // Update reference
  await octokit.git.updateRef({
    owner: org,
    repo: repoName,
    ref: `heads/${defaultBranch}`,
    sha: newCommit.sha
  });

  context.log('Files pushed successfully', {
    commitSha: newCommit.sha,
    fileCount: files.length
  });
}

/**
 * Configure Branch Protection
 *
 * Establishes branch protection rules on default branch.
 *
 * @param {Octokit} octokit - GitHub API client
 * @param {string} org - Organization name
 * @param {string} repoName - Repository name
 * @param {object} context - Function context
 */
async function configureBranchProtection(octokit, org, repoName, context) {
  try {
    const { data: repo } = await octokit.repos.get({
      owner: org,
      repo: repoName
    });
    const defaultBranch = repo.default_branch || 'main';

    await octokit.repos.updateBranchProtection({
      owner: org,
      repo: repoName,
      branch: defaultBranch,
      required_status_checks: null,  // No required status checks initially
      enforce_admins: false,          // Allow admins to bypass
      required_pull_request_reviews: null,  // No PR reviews required for autonomous builds
      restrictions: null,
      required_linear_history: false,
      allow_force_pushes: false,
      allow_deletions: false
    });

    context.log('Branch protection configured', { branch: defaultBranch });

  } catch (error) {
    context.log.warn('Failed to configure branch protection (may require admin permissions)', {
      error: error.message
    });
    // Don't throw - branch protection is nice-to-have, not critical
  }
}

/**
 * Add Repository Topics
 *
 * Tags repository with relevant topics for discoverability.
 *
 * @param {Octokit} octokit - GitHub API client
 * @param {string} org - Organization name
 * @param {string} repoName - Repository name
 * @param {object} context - Function context
 */
async function addRepositoryTopics(octokit, org, repoName, context) {
  try {
    const topics = [
      'autonomous-build',
      'ai-generated',
      'brookside-bi',
      'innovation-platform',
      'azure',
      'microsoft'
    ];

    await octokit.repos.replaceAllTopics({
      owner: org,
      repo: repoName,
      names: topics
    });

    context.log('Repository topics added', { topics });

  } catch (error) {
    context.log.warn('Failed to add repository topics', {
      error: error.message
    });
    // Don't throw - topics are nice-to-have
  }
}

/**
 * Sleep Utility
 *
 * Delays execution for specified milliseconds.
 *
 * @param {number} ms - Milliseconds to sleep
 * @returns {Promise} Promise that resolves after delay
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
