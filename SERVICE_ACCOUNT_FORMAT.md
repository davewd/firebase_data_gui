# Firebase Service Account Key Format

This document describes the expected format of the Firebase service account JSON key file.

## Required Fields

The JSON file must contain the following fields:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/...",
  "universe_domain": "googleapis.com"
}
```

## Optional Fields

The app also supports optional `database_url` and `database_region` fields:

```json
{
  "database_url": "https://your-project-id-default-rtdb.asia-southeast1.firebasedatabase.app",
  "database_region": "asia-southeast1",
  ...other fields...
}
```

For regional databases (for example `asia-southeast1`), add `database_region` to your JSON key file. If you already know the full endpoint, you can set `database_url` directly to a `.firebasedatabase.app` URL. The app's Authentication Details view shows the Database Region value from `database_region`.

If `database_url` is not provided but `database_region` is, the database URL will be constructed as:
`https://{project_id}-default-rtdb.{database_region}.firebasedatabase.app`

If neither field is provided, the database URL will be constructed automatically as:
`https://{project_id}-default-rtdb.firebaseio.com`

## Security Notes

⚠️ **NEVER commit this file to version control!**

- This file grants full access to your Firebase project
- Keep it secure and private
- The .gitignore file is configured to exclude common service key filenames
- Always use environment-specific keys (dev/staging/prod)

## Getting Your Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Save the downloaded JSON file in a secure location

## Validation

The app validates the presence of:
- `project_id` - Your Firebase project identifier
- `private_key` - RSA private key for authentication
- `client_email` - Service account email address

If any of these are missing, you'll see an error message.

## Troubleshooting Private Key Errors

- The `private_key` field must include the full PEM header and footer:
  `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`.
- If you see messages like "Unable to load private key" or "Unable to sign JWT", download a fresh service account JSON key from the Firebase console.
- If you copied the key into another file, replace the two-character sequence `\n` in the `private_key` value with actual newline characters.
- Whenever possible, use the original JSON file downloaded from Firebase instead of copying the key manually.
