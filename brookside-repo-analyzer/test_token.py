#!/usr/bin/env python
"""Test GitHub token validity."""
import asyncio
import httpx
from src.auth import CredentialManager
from src.config import get_settings

async def main():
    settings = get_settings()
    cred_manager = CredentialManager(settings)
    token = cred_manager.github_token

    print(f"Token retrieved: {token[:20]}...")

    async with httpx.AsyncClient() as client:
        # Test authentication
        response = await client.get(
            "https://api.github.com/user",
            headers={"Authorization": f"token {token}"}
        )

        print(f"\nStatus: {response.status_code}")

        if response.status_code == 200:
            user_data = response.json()
            print(f"✅ Token is VALID")
            print(f"Username: {user_data.get('login')}")
            print(f"Public Repos: {user_data.get('public_repos')}")
        else:
            print(f"❌ Token is INVALID")
            print(f"Response: {response.text}")

if __name__ == "__main__":
    asyncio.run(main())
