#!/usr/bin/env python
"""Quick script to check GitHub authenticated user."""
import asyncio
import httpx
from src.auth import CredentialManager
from src.config import get_settings

async def main():
    settings = get_settings()
    cred_manager = CredentialManager(settings)
    token = cred_manager.github_token

    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://api.github.com/user",
            headers={"Authorization": f"token {token}"}
        )
        user_data = response.json()
        print(f"GitHub Username: {user_data.get('login')}")
        print(f"User Type: {user_data.get('type')}")
        print(f"Public Repos: {user_data.get('public_repos')}")

        # Get organizations
        orgs_response = await client.get(
            "https://api.github.com/user/orgs",
            headers={"Authorization": f"token {token}"}
        )
        orgs = orgs_response.json()
        print(f"\nOrganizations ({len(orgs)}):")
        for org in orgs:
            print(f"  - {org['login']}")

if __name__ == "__main__":
    asyncio.run(main())
