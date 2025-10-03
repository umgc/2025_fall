# EduLense AWS Deployment - Step by Step Guide

## Prerequisites Checklist

Before starting, make sure you have:
- [ ] AWS account created
- [ ] At least ONE AI API key (OpenAI, Perplexity, or Grok)
- [ ] GitHub account
- [ ] Windows 10/11 with PowerShell

## Tools You Need to Install

- [ ] Git for Windows: https://git-scm.com/downloads/win
- [ ] AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- [ ] Terraform: https://developer.hashicorp.com/terraform/install

**Note:** You do NOT need Docker or WSL2 for this deployment.

---

## Step 1: AWS Account Setup

### 1.1 Create AWS Account
1. Go to https://aws.amazon.com/
2. Click "Create an AWS Account"
3. Complete identity verification (requires credit card and phone verification)
4. Sign in to AWS Console

### 1.2 Create IAM User for Terraform
1. In AWS Console, search for "IAM" and open it
2. Click "Users" → "Create user"
3. Enter username: `terraform-user`
4. Click "Next"
5. Select "Attach policies directly"
6. Search and select: `AdministratorAccess` (for simplicity; restrict later if needed)
7. Click "Next" → "Create user"

### 1.3 Create Access Keys
1. Click on the newly created user
2. Go to "Security credentials" tab
3. Scroll to "Access keys" → Click "Create access key"
4. Select "Command Line Interface (CLI)"
5. Check the confirmation box → Click "Next"
6. Add description (optional) → Click "Create access key"
7. **IMPORTANT:** Copy both:
   - Access key ID
   - Secret access key
   (You won't see the secret again!)

### 1.4 Set Windows Environment Variables
1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Go to "Advanced" tab → Click "Environment Variables"
3. Under "User variables", click "New"
4. Add first variable:
   - Variable name: `AWS_ACCESS_KEY_ID`
   - Variable value: `<paste your access key ID>`
5. Click "New" again for second variable:
   - Variable name: `AWS_SECRET_ACCESS_KEY`
   - Variable value: `<paste your secret access key>`
6. Click "OK" on all windows
7. **Restart PowerShell** for changes to take effect

---

## Step 2: Install Required Tools

### 2.1 Install Git
1. Download from: https://git-scm.com/downloads/win
2. Run installer with default options
3. Verify installation:
```powershell
git --version
```

### 2.2 Install AWS CLI
1. Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Run installer
3. Verify installation:
```powershell
aws --version
```

### 2.3 Install Terraform
1. Download from: https://developer.hashicorp.com/terraform/install
2. Extract the .exe file
3. Move `terraform.exe` to `C:\Program Files\Terraform\`
4. Add to PATH:
   - Press `Win + R`, type `sysdm.cpl`, press Enter
   - Go to "Advanced" → "Environment Variables"
   - Under "System variables", find "Path" → Click "Edit"
   - Click "New" → Add `C:\Program Files\Terraform`
   - Click "OK" on all windows
5. **Restart PowerShell**
6. Verify installation:
```powershell
terraform --version
```

---

## Step 3: Get AI API Key

You need **at least ONE** of these:

### Option A: OpenAI
1. Go to https://platform.openai.com
2. Sign up / Log in
3. Go to "API keys" → "Create new secret key"
4. Add billing information and credits ($5-10 recommended)
5. Copy the API key

### Option B: Perplexity
1. Go to https://www.perplexity.ai/
2. Sign up / Log in
3. Go to Settings → API
4. Generate API key
5. Copy the API key

### Option C: Grok (xAI)
1. Go to https://console.x.ai
2. Sign up / Log in
3. Create API key
4. Enable billing/credits
5. Copy the API key

**Save your API key somewhere safe!**

---

## Step 4: GitHub Setup

### 4.1 Fork the Repository (if needed)
1. Go to your GitHub repo (or fork from upstream)
2. Make sure you have access to the code

### 4.2 Create Personal Access Token (PAT)
1. Go to GitHub → Settings (your profile settings)
2. Scroll down → Click "Developer settings"
3. Click "Personal access tokens" → "Tokens (classic)"
4. Click "Generate new token" → "Generate new token (classic)"
5. Add note: `EduLense Terraform`
6. Set expiration: End of semester
7. Select scopes:
   - [x] `repo` (all)
   - [x] `admin:repo_hook` (all)
8. Click "Generate token"
9. **IMPORTANT:** Copy the token (you won't see it again!)

---

## Step 5: Clone Repository

Open PowerShell and run:

```powershell
cd C:\Users\work\Desktop\learninglens\2025_fall
git pull
```

(Since you already have the repo, just make sure it's up to date)

---

## Step 6: Create .env File

```powershell
cd LearningLens2025\teamA
copy .example.env .env
notepad .env
```

Fill in what you have now:
```
openai_apikey=sk-proj-xxxxx
MOODLE_USERNAME=
MOODLE_PASSWORD=
MOODLE_URL=
perplexity_apikey=
grokKey=
GOOGLE_CLIENT_ID=
AI_LOGGING_URL=
```

**Note:** Only fill in the AI API key you have. Leave the rest blank for now.

Save and close the file.

---

## Step 7: Run Terraform (Initial Deployment)

```powershell
cd ..\terraform_N
terraform init
```

Wait for initialization to complete, then:

```powershell
terraform apply -var "github_token=YOUR_GITHUB_PAT_HERE"
```

Replace `YOUR_GITHUB_PAT_HERE` with your actual GitHub token.

When prompted, type: `yes`

**This will take 5-10 minutes.** Terraform is creating:
- VPC and networking
- EC2 instance with Moodle
- Lambda function for AI logging
- AWS Amplify app for the Flutter web app

---

## Step 8: Save Terraform Outputs

After terraform completes successfully:

```powershell
terraform show > terraformout.txt
notepad terraformout.txt
```

Find and copy these values:
- `public_dns` = (looks like `ec2-xx-xx-xx-xx.compute-1.amazonaws.com`)
- `function_url` = (Lambda function URL)
- `default_domain` = (Amplify domain)
- `display_name` = (Amplify app name)

**Save these values in a text file for reference!**

---

## Step 9: Get Moodle Credentials

```powershell
ssh -i keys\moodle-app-key.pem bitnami@YOUR_PUBLIC_DNS_HERE
```

Replace `YOUR_PUBLIC_DNS_HERE` with the `public_dns` from Step 8.

Once connected, run:
```bash
cat bitnami_credentials
```

Copy the username and password shown.

Type `exit` to disconnect.

---

## Step 10: Configure Moodle

### 10.1 Login to Moodle
1. Open browser and go to: `https://YOUR_PUBLIC_DNS`
2. Login with credentials from Step 9
3. Accept any security warnings (self-signed certificate)

### 10.2 Enable Web Services
1. Click "Site administration" (left sidebar)
2. Go to "Advanced features"
3. Check these boxes:
   - [x] Enable web services
   - [x] Enable mobile web service
4. Click "Save changes"

### 10.3 Enable REST Protocol
1. Site administration → Server → Web services → Manage protocols
2. Enable "REST protocol"
3. Enable "SOAP protocol"
4. Click "Save changes"

### 10.4 Install Learning Lens Plugin
1. Site administration → Plugins → Install plugins
2. Click "Choose a file"
3. Navigate to: `C:\Users\work\Desktop\learninglens\2025_fall\LearningLens2025\MoodlePlugin\`
4. Select `learninglens.zip`
5. Click "Install plugin from the ZIP file"
6. Follow prompts until you see "Success"

---

## Step 11: Create Moodle Student User

1. Site administration → Users → Accounts → Add a new user
2. Fill in:
   - Username: `student1`
   - Authentication method: `Manual accounts`
   - Password: ("Zv96[G5s£~K7")
   - First name: `Test`
   - Last name: `Student`
   - Email: `student1@edulense.com` (can be fake)
3. Click "Create user"
4. **Save the username and password!**

---

## Step 12: Create Moodle Course

### 12.1 Create Course
1. Click "Site home" (top left)
2. Click "Courses" → "Add a new course"
3. Fill in:
   - Course full name: `Test Course`
   - Course short name: `TEST101`
   - Course category: `Miscellaneous`
   - Course ID number: `TEST101`
   - Visibility: `Show`
   - Course start date: (set to past date, e.g., last month)
   - Course end date: (set to future date, e.g., next year)
4. Click "Save and display"

### 12.2 Enroll Student
1. In the course, click "Participants" (left sidebar)
2. Click "Enrol users"
3. Search for `student1`
4. Select role: `Student`
5. Click "Enrol"
6. Verify both "Admin" (Teacher) and "student1" (Student) are listed

---

## Step 13: Complete .env File

```powershell
cd C:\Users\work\Desktop\learninglens\2025_fall\LearningLens2025\teamA
notepad .env
```

Update with the values you now have:

```
openai_apikey=sk-proj-xxxxx
MOODLE_USERNAME=student1
MOODLE_PASSWORD=your_student_password
MOODLE_URL=https://YOUR_PUBLIC_DNS
perplexity_apikey=
grokKey=
GOOGLE_CLIENT_ID=
AI_LOGGING_URL=YOUR_FUNCTION_URL
```

Replace:
- `YOUR_PUBLIC_DNS` with the public_dns from Step 8
- `YOUR_FUNCTION_URL` with the function_url from Step 8
- `your_student_password` with the password you created

Save and close.

---

## Step 14: Re-run Terraform to Push Config

```powershell
cd ..\terraform_N
terraform apply -var "github_token=YOUR_GITHUB_PAT_HERE"
```

Type: `yes`

This updates the Amplify app with your .env configuration.

---

## Step 15: Deploy Amplify App

### 15.1 Manual Deploy
1. Go to AWS Console: https://console.aws.amazon.com
2. Search for "Amplify" and open it
3. Click on your app (should be named from `display_name`)
4. Click on the branch (likely `team_e` or `main`)
5. Click "Redeploy this version"
6. Wait for build to complete (5-10 minutes)

### 15.2 Access Your App
1. Once deployed, visit: `https://DISPLAY_NAME.DEFAULT_DOMAIN`
   (Use the values from Step 8)
2. The app should auto-login as the student user
3. You should see the Moodle course and content

---

## Step 16: Test the App

1. App should show your Moodle course
2. Try switching users using the settings icon
3. Try the LMS dropdown to switch between Moodle/Google Classroom (if configured)
4. Test AI features with your course content

---

## Troubleshooting

### Terraform fails with "InvalidAccessKeyId"
- Check that AWS environment variables are set correctly
- Restart PowerShell after setting environment variables

### Cannot SSH to EC2
- Make sure you're in the `terraform_N` folder when running SSH command
- Check that `keys\moodle-app-key.pem` file exists

### Moodle not accessible via HTTPS
- Wait 2-3 minutes after terraform completes
- Check security groups in AWS Console

### Amplify app shows 404
- Wait for DNS propagation (can take 5-10 minutes)
- Try redeploying the branch explicitly
- Verify the URL matches terraform outputs

### App doesn't auto-login
- Verify .env file has correct MOODLE_USERNAME and MOODLE_URL
- Re-run terraform apply after updating .env
- Redeploy Amplify app

---

## Success Criteria

You're done when:
- [x] Terraform applies successfully twice (initial + finalize)
- [x] Moodle is accessible at `https://public_dns`
- [x] Learning Lens plugin installed successfully
- [x] Student user created and enrolled in course
- [x] Amplify app deployed and accessible
- [x] App auto-login works
- [x] Can see Moodle course content in the app

---

## Important URLs to Save

- Moodle: `https://YOUR_PUBLIC_DNS`
- App: `https://DISPLAY_NAME.DEFAULT_DOMAIN`
- Lambda Function: `YOUR_FUNCTION_URL`
- AWS Console: https://console.aws.amazon.com

---

## Next Steps After Deployment

1. Add more courses and content in Moodle
2. Test AI features with different prompts
3. Configure Google Classroom integration (optional)
4. Invite other users to test
5. Monitor AWS costs in billing dashboard

---

**Need help?** Check the troubleshooting section or review the original instructions.md file.
