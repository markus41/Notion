"""
Quick test script to verify credential loading and configuration

This validates:
- Configuration loading from .env
- Azure Key Vault authentication
- GitHub token retrieval
- Notion workspace configuration
"""

import asyncio
import sys

from src.auth import CredentialManager
from src.config import get_settings


async def main():
    print("Brookside BI Repository Analyzer - Credential Test\n")

    # Test 1: Load configuration
    print("[TEST] Configuration loading...")
    try:
        settings = get_settings()
        print(f"  [OK] Azure Key Vault: {settings.azure.keyvault_name}")
        print(f"  [OK] GitHub Organization: {settings.github.organization}")
        print(f"  [OK] Notion Workspace: {settings.notion.workspace_id}")
        print(f"  [OK] Analysis Settings: Deep={settings.analysis.deep_analysis_enabled}, "
              f"Claude={settings.analysis.detect_claude_configs}")
    except Exception as e:
        print(f"  [FAIL] Configuration loading failed: {e}")
        return False

    # Test 2: Initialize credential manager
    print("\n[TEST] Credential manager initialization...")
    try:
        credentials = CredentialManager(settings)
        print(f"  [OK] Credential manager initialized")
    except Exception as e:
        print(f"  [FAIL] Credential manager failed: {e}")
        return False

    # Test 3: Validate credentials
    print("\n[TEST] Credential validation...")
    try:
        validation = credentials.validate_credentials()
        print(f"  [OK] GitHub credentials: {'VALID' if validation['github'] else 'INVALID'}")
        print(f"  [OK] Notion credentials: {'VALID' if validation['notion'] else 'INVALID'}")

        if not validation['github']:
            print("  [WARN] GitHub token not found or invalid")
            return False

    except Exception as e:
        print(f"  [FAIL] Credential validation failed: {e}")
        return False

    # Test 4: Retrieve GitHub token
    print("\n[TEST] GitHub token retrieval...")
    try:
        github_token = credentials.github_token
        # Only show first/last characters for security
        masked_token = f"{github_token[:15]}...{github_token[-10:]}"
        print(f"  [OK] GitHub token retrieved: {masked_token}")
    except Exception as e:
        print(f"  [FAIL] GitHub token retrieval failed: {e}")
        return False

    print("\n[SUCCESS] All credential tests passed!")
    print("\nNext steps:")
    print("  1. Run: poetry run brookside-analyze scan --quick")
    print("  2. Test full organization scan")
    print("  3. Deploy to Azure Function")

    return True


if __name__ == "__main__":
    result = asyncio.run(main())
    sys.exit(0 if result else 1)
