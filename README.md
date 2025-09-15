# AWS Nuke - GitLab Pipeline

A GitLab CI/CD pipeline for safely nuking AWS accounts using [aws-nuke](https://github.com/ekristen/aws-nuke) with automated configuration management and multi-stage approval process.

## Overview

This project provides a secure, automated way to completely clean AWS accounts by removing all resources. It's designed for scenarios like:
- Cleaning up development/test accounts
- Account closure procedures
- Resource cleanup after testing
- Preparing accounts for handover

## Features

- **Multi-stage approval process** - Two manual approval gates before execution
- **Dry-run validation** - Always runs a dry-run first to show what will be deleted
- **Flexible account configuration** - Supports accounts with and without aliases
- **Comprehensive resource exclusions** - Pre-configured to exclude deprecated and problematic resources
- **Detailed logging** - Captures all operations with timestamped logs
- **Role-based access** - Uses AWS STS assume role for secure cross-account operations

## Project Structure

```
├── .gitlab-ci.yml              # Main CI/CD pipeline configuration
├── config-with-alias.yml       # aws-nuke config template for accounts with aliases
├── config-without-alias.yml    # aws-nuke config template for accounts without aliases
├── scripts/
│   └── prepare-config.sh       # Script to generate final config from templates
├── close-account/
│   └── nuke.yml               # Account registry for tracking accounts to be nuked
└── README.md                  # This file
```

## Pipeline Stages

### 1. Detect Changes
- Monitors changes to `close-account/nuke.yml`
- Extracts account information (ID, CLSP, alias if present)
- Only triggers when nuke.yml is modified in merge requests to main

### 2. Display Account
- Shows the account details that will be processed
- Provides visibility into what account will be affected

### 3. Manual Approval 1
- **MANUAL GATE**: Requires human approval before dry-run
- Shows account details for verification

### 4. Dry Run
- Downloads aws-nuke from GitHub releases
- Assumes `AWSAFTExecution` role in target account
- Runs aws-nuke in dry-run mode
- Generates detailed log of resources that would be removed
- Does not actually delete anything

### 5. Manual Approval 2
- **MANUAL GATE**: Requires human approval before execution
- Final confirmation before actual resource deletion

### 6. Execute
- Performs actual aws-nuke execution
- Permanently deletes all identified resources
- Generates execution log with deleted resources

## Configuration

### Account Registry (`close-account/nuke.yml`)

Add accounts to be nuked in this format:

```yaml
Accounts:
  - "AccountId": "123456789012"
    "CLSP": "my-account-identifier"
  - "AccountId": "987654321098"
    "CLSP": "another-account"
    "AccountAlias": "my-account-alias"  # Optional
```

### AWS Nuke Configuration

The pipeline uses two template configurations:

- `config-with-alias.yml` - For accounts that have an AWS account alias
- `config-without-alias.yml` - For accounts without an alias

Both configurations exclude:
- Deprecated AWS services (OpsWorks, CodeStar, Cloud9, etc.)
- Problematic resources (ServiceCatalog items, ML services)
- IAM roles and policies (to avoid breaking access)
- S3Objects (handled by S3 bucket deletion)

### Excluded Resource Types

The configuration excludes several resource types for safety and compatibility:

- **Deprecated Services**: OpsWorks, CodeStar, Cloud9, CloudSearch, RoboMaker
- **Machine Learning**: All ML-related resources (service unavailable)
- **Service Catalog**: Tag options and attachments (known issues)
- **IAM**: Roles and policies (to maintain access during cleanup)
- **S3Objects**: Handled automatically by S3 bucket deletion

## Prerequisites

### AWS Setup
1. Target accounts must have `AWSAFTExecution` role
2. Pipeline execution role must be able to assume roles in target accounts
3. Accounts should not be production accounts (use blocklist protection)

### GitLab Setup
1. GitLab runner with `test-runner` tag
2. AWS credentials configured for the runner
3. Required tools: `curl`, `tar`, `jq`, `aws-cli`

## Usage

### Adding an Account for Cleanup

1. Create a merge request to main branch
2. Edit `close-account/nuke.yml` and add your account:
   ```yaml
   Accounts:
     - "AccountId": "YOUR_ACCOUNT_ID"
       "CLSP": "your-identifier"
       "AccountAlias": "your-alias"  # Optional
   ```
3. Submit the merge request
4. Pipeline will automatically trigger and require two manual approvals

### Pipeline Execution

1. **Automatic Detection**: Pipeline detects changes to nuke.yml
2. **Review Account Info**: Check the displayed account details
3. **First Approval**: Approve to proceed with dry-run
4. **Review Dry-run Results**: Examine what resources will be deleted
5. **Second Approval**: Final approval for actual execution
6. **Execution**: Resources are permanently deleted

## Safety Features

### Blocklist Protection
- Production account `123456789012` is blocklisted
- Add additional production accounts to the blocklist in config templates

### Multi-stage Approval
- Two manual approval gates prevent accidental execution
- Clear warnings about permanent deletion

### Dry-run First
- Always shows what will be deleted before actual execution
- Allows review and cancellation if needed

### Role-based Access
- Uses temporary credentials via STS assume role
- Credentials are automatically cleaned up after use

## Logs and Artifacts

The pipeline generates several artifacts:

- `aws-nuke-removal-*.log` - Dry-run results showing resources to be removed
- `aws-nuke-execution-*.log` - Execution results showing deleted resources
- `config-prepared.yml` - Final configuration used for aws-nuke
- `account_info.env` - Account details for pipeline stages

Artifacts are retained for 1 day for review and troubleshooting.

## Troubleshooting

### Common Issues

**Pipeline doesn't trigger**
- Ensure changes are made to `close-account/nuke.yml`
- Verify merge request targets the `main` branch

**Role assumption fails**
- Check that `AWSAFTExecution` role exists in target account
- Verify trust relationship allows assumption from pipeline role

**aws-nuke exits with warnings**
- This is normal - some resources may not be deletable due to dependencies
- Check logs to see what was and wasn't deleted
- Pipeline continues even with warnings

**Config preparation fails**
- Verify account ID format in nuke.yml
- Check that alias is provided when HAS_ALIAS is true

### Manual Cleanup

If the pipeline fails partway through, you may need to:

1. Check the execution logs for partially deleted resources
2. Manually clean up any remaining resources
3. Re-run the pipeline if needed

## Security Considerations

- Never run against production accounts
- Always review dry-run results carefully
- Ensure proper IAM permissions and role trust relationships
- Monitor execution logs for any unexpected behavior
- Keep the blocklist updated with protected accounts

## Contributing

1. Test changes in a non-production environment first
2. Update documentation for any configuration changes
3. Follow the existing code style and structure
4. Ensure all safety features remain intact

## License

MIT License - see LICENSE file for details.

## Disclaimer

⚠️ **WARNING**: This tool permanently deletes AWS resources. Use with extreme caution and always test in non-production environments first. The authors are not responsible for any data loss or service disruption caused by the use of this tool.
