#!/usr/bin/env python3
"""
Link Validation Script for Brookside BI Innovation Nexus
Validates all internal markdown links across the project.
"""

import re
import os
from pathlib import Path
from typing import List, Dict, Tuple

# Link validation results
total_links = 0
broken_links = []
external_links = 0

# Regex patterns
link_pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')
header_pattern = re.compile(r'^#{1,6}\s+(.+)$', re.MULTILINE)

def normalize_anchor(text: str) -> str:
    """Convert header text to anchor format (GitHub-style)"""
    anchor = text.lower()
    # Remove emojis and special characters
    anchor = re.sub(r'[^\w\s-]', '', anchor)
    # Replace spaces and underscores with hyphens
    anchor = re.sub(r'[\s_]+', '-', anchor)
    # Remove leading/trailing hyphens
    anchor = anchor.strip('-')
    return anchor

def extract_headers(content: str) -> List[str]:
    """Extract all headers from markdown content"""
    headers = header_pattern.findall(content)
    return [normalize_anchor(h) for h in headers]

def validate_link(source_file: Path, link_text: str, link_target: str, line_num: int, base_dir: Path):
    """Validate a single link"""
    global total_links, broken_links, external_links
    total_links += 1

    # Skip external URLs
    if link_target.startswith(('http://', 'https://', 'mailto:', 'ftp://')):
        external_links += 1
        return

    # Skip collection:// and other special protocols
    if '://' in link_target:
        return

    # Parse target (file and anchor)
    target_parts = link_target.split('#', 1)
    target_file = target_parts[0] if target_parts[0] else None
    target_anchor = target_parts[1] if len(target_parts) > 1 else None

    # Resolve target file path
    if target_file:
        # Handle absolute vs relative paths
        if os.path.isabs(target_file):
            target_path = Path(target_file)
        else:
            # Relative to source file's directory
            target_path = (source_file.parent / target_file).resolve()
    else:
        # Same file anchor reference
        target_path = source_file

    # Check if file exists
    if target_file and not target_path.exists():
        broken_links.append({
            'file': str(source_file.relative_to(base_dir)),
            'line': line_num,
            'link_text': link_text,
            'target': link_target,
            'error': f'File not found: {target_file}'
        })
        return

    # Check if anchor exists (if specified)
    if target_anchor:
        try:
            content = target_path.read_text(encoding='utf-8', errors='ignore')
            headers = extract_headers(content)

            if target_anchor not in headers:
                # Show available headers for debugging
                available = ', '.join(headers[:5]) if headers else 'none'
                broken_links.append({
                    'file': str(source_file.relative_to(base_dir)),
                    'line': line_num,
                    'link_text': link_text,
                    'target': link_target,
                    'error': f'Anchor not found: #{target_anchor} (available: {available}...)'
                })
        except Exception as e:
            broken_links.append({
                'file': str(source_file.relative_to(base_dir)),
                'line': line_num,
                'link_text': link_text,
                'target': link_target,
                'error': f'Error reading target file: {e}'
            })

def main():
    """Main link validation process"""
    base_dir = Path(__file__).parent

    # File patterns to check
    patterns = [
        'CLAUDE.md',
        '.claude/agents/*.md',
        '.claude/commands/**/*.md',
        '.claude/templates/*.md',
        '.claude/docs/patterns/*.md'
    ]

    # Collect all markdown files
    files_to_check = []
    for pattern in patterns:
        if '**' in pattern:
            parts = pattern.split('**/')
            base_path = base_dir / parts[0].strip('/')
            glob_pattern = parts[1]
            files_to_check.extend(base_path.rglob(glob_pattern))
        elif '*' in pattern:
            files_to_check.extend(base_dir.glob(pattern))
        else:
            file_path = base_dir / pattern
            if file_path.exists():
                files_to_check.append(file_path)

    print(f"Checking {len(files_to_check)} markdown files...")

    # Process each file
    for md_file in files_to_check:
        try:
            content = md_file.read_text(encoding='utf-8', errors='ignore')
            lines = content.split('\n')

            for line_num, line in enumerate(lines, 1):
                matches = link_pattern.findall(line)
                for link_text, link_target in matches:
                    validate_link(md_file, link_text, link_target, line_num, base_dir)
        except Exception as e:
            print(f'Error processing {md_file.relative_to(base_dir)}: {e}')

    # Report results
    print('\n' + '=' * 60)
    print('LINK VALIDATION REPORT')
    print('=' * 60)
    print(f'Total internal links checked: {total_links - external_links}')
    print(f'External links (not validated): {external_links}')
    print(f'Broken links found: {len(broken_links)}')

    if broken_links:
        print('\n' + '-' * 60)
        print('BROKEN LINKS DETAIL')
        print('-' * 60)
        for link in broken_links:
            print(f"\nFile: {link['file']}:{link['line']}")
            print(f"  Link: [{link['link_text']}]({link['target']})")
            print(f"  Error: {link['error']}")
        print('\n' + '=' * 60)
        return 1
    else:
        print('\nAll internal links are valid!')
        print('=' * 60)
        return 0

if __name__ == '__main__':
    exit(main())
