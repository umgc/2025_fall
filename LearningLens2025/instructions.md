doc:
  title: "EduLense Deployment Guide"
  version: "1.0"
  date: "2025-09-13"
  project_code: "SWEN 670: Software Engineering Capstone"
  institution: "University of Maryland Global Campus"
  faculty_mentor: "Dr. Mir Assadullah"
  authors:
    - Andreas Hochmuth
    - Cody White
    - Matthew McDaniel
    - Ryan Appleby
    - Si Young Sung
    - Sneha Philip
    - William Freeman

  revision_history:
    - date: "2025-09-18"
      version: "1.0"
      description: "Initial Draft of Section 4"
      author: "Ryan Appleby"

  sign_off:
    - date: "2025-09-13"
      version: "1.x.x"
      signer: "William Freman"
      role: "Team Lead"

  # Known Issues / Corrections that matter for real deployments.
  corrections_and_warnings:
    - id: WARN-AWS-CC
      scope: "AWS Account Setup"
      message: "AWS Free Tier still requires a valid payment method and identity verification. 'No payment information is required' is incorrect in practice."
      action: "Plan for a credit card and address/phone verification during signup."
    - id: WARN-AMPLIFY-FIRST-BUILD
      scope: "AWS Amplify"
      message: "First build and syncs do not auto-deploy; manual redeploy is required."
      action: "Explicitly trigger 'Deploy' or 'Redeploy this version' on the Amplify app/branch."
    - id: WARN-GC-EDU-PLUS
      scope: "Google Classroom Features"
      message: "Rubrics, Add-Ons, and SIS features require specific paid EDU SKUs (Education Plus, T&L Upgrade, or Instructional Upgrade)."
      action: "Confirm licenses before relying on those APIs."

  overview:
    purpose: "Stand up EduLense on AWS with Terraform, Docker, Amplify, Moodle, and optional Google Classroom integration."
    scope: ["Infrastructure provisioning", "App build/deploy", "LMS configuration (Moodle, optional Google Classroom)"]
    intended_audience: ["DevOps", "Developers", "Course staff"]
    project_documents: []
    acronyms:
      IAM: "Identity and Access Management"
      IaC: "Infrastructure as Code"
      CLI: "Command Line Interface"
      WSL2: "Windows Subsystem for Linux 2"
      LMS: "Learning Management System"
      URL: "Uniform Resource Locator"
    references:
      - name: "AWS"
        url: "https://aws.amazon.com"
      - name: "AWS CLI Install"
        url: "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
      - name: "Terraform Install"
        url: "https://developer.hashicorp.com/terraform/install"
      - name: "Docker Desktop (Windows)"
        url: "https://docs.docker.com/desktop/setup/install/windows-install/"
      - name: "Git for Windows"
        url: "https://git-scm.com/downloads/win"
      - name: "Google Cloud Console"
        url: "https://console.cloud.google.com"
      - name: "Google Classroom"
        url: "https://classroom.google.com"
      - name: "GitHub"
        url: "https://github.com/"

  platform_requirements:
    os: "Windows 10/11 (PowerShell, WSL2, Docker Desktop)"
    hardware:
      virtualization: true
    accounts:
      - provider: "AWS"
        role: "Root + IAM Admin (for setup), Terraform IAM user"
      - provider: "GitHub"
        role: "Repo Owner of fork"
      - provider: "Google"
        role: "GCP Project Owner (for Classroom integration)"
      - provider: "OpenAI/Perplexity/xAI (Grok)"
        role: "API billing enabled"
    licenses:
      google_edu_plus_features_required: true

  variables:
    env_vars_windows_user_scope:
      - name: "AWS_ACCESS_KEY_ID"
        source: "IAM access key for Terraform user"
      - name: "AWS_SECRET_ACCESS_KEY"
        source: "IAM secret access key for Terraform user"
    dot_env_fields (LearningLense2025/teamA/.env):
      - name: "openai_apikey"
        required: false
      - name: "perplexity_api"
        required: false
      - name: "grokKey"
        required: false
      - name: "MOODLE_USERNAME"
        required: true
      - name: "MOODLE_URL"
        required: true
        example: "https://<public_dns>"
      - name: "GOOGLE_CLIENT_ID"
        required: false
      - name: "AI_LOGGING_URL"
        required: true
    terraform_outputs_expected:
      - "public_dns (two entries, both starting with 'ec2')"
      - "function_url"
      - "default_domain"
      - "display_name"

  tools:
    - name: "Git"
      verify_cmd: "git --version"
    - name: "AWS CLI"
      verify_cmd: "aws --version"
    - name: "Docker Desktop"
      verify_cmd: "docker --version"
    - name: "Terraform"
      verify_cmd: "terraform --version"
    - name: "WSL2"
      verify_cmd: "wsl --help"

  repositories:
    upstream_repo: "https://github.com/umgc/2025_fall"
    branch_of_record: "team_e"
    learner_repo_name: "2025_fall (forked under deployer account)"

  high_level_flow:
    - "Create AWS account, IAM Terraform user, and set AWS credentials as user env vars on Windows."
    - "Install Git, AWS CLI, Docker Desktop (ensure virtualization + WSL2), Terraform."
    - "Obtain at least one LLM provider API key (OpenAI OR Perplexity OR Grok)."
    - "Create Google Cloud project + Classroom APIs (optional but required for GC features)."
    - "Fork GitHub repo (umgc/2025_fall), ensure branch team_e, generate PAT token."
    - "Clone fork; prepare .env from .envtemplate."
    - "Run Terraform (initial); record outputs (public_dns, function_url, default_domain, display_name)."
    - "SSH to Moodle host; retrieve credentials; configure Moodle; install plugin(s)."
    - "Create Moodle student, course, enrollments."
    - "Complete .env; re-run Terraform to push config to Amplify."
    - "Manual Amplify deploy/redeploy on branch team_e; visit final URL."
    - "Use in-app settings to switch LMS / sign out/in as needed."

  steps:
    - id: AWS-1
      title: "Create AWS Account (Free Tier)"
      actions:
        - "Sign up at https://aws.amazon.com/"
        - "Complete identity verification; add payment method (required by AWS)."
      output: "Root account created; access to console."
      warnings: ["WARN-AWS-CC"]

    - id: AWS-2
      title: "Create IAM User for Terraform"
      actions:
        - "Open IAM service → Users → Create user."
        - "Name user; Next; add to 'admins' group (broad permissions; restrict later if desired)."
        - "Create access key: Security credentials → Access keys → Create (Other)."
        - "Store access key ID and secret securely."
      post_actions_windows_env:
        - var: "AWS_ACCESS_KEY_ID"
          value: "<your access key id>"
        - var: "AWS_SECRET_ACCESS_KEY"
          value: "<your secret access key>"

    - id: WIN-TOOLS
      title: "Install Required Tools on Windows"
      actions:
        - "Install Git for Windows; verify: git --version"
        - "Install AWS CLI; verify: aws --version"
        - "Enable virtualization (BIOS/UEFI) if disabled."
        - "Enable WSL2: wsl --install (or confirm help text)."
        - "Install Docker Desktop; verify: docker --version"
        - "Install Terraform; add to PATH; verify: terraform --version"

    - id: API-KEYS
      title: "Obtain at least one AI Provider API Key"
      providers:
        openai:
          url: "https://platform.openai.com"
          notes:
            - "Create API key; billing with credit card and funds required."
        perplexity:
          url: "https://www.perplexity.ai/"
          notes:
            - "Generate API key in Settings → API."
        grok:
          url: "https://console.x.ai"
          notes:
            - "Create API key; enable billing/credits."
      requirement: "At least one of openai_apikey | perplexity_api | grokKey must be present."

    - id: GCP-CLASSROOM
      title: "Google Cloud Project & Classroom APIs (Optional for GC features)"
      actions:
        - "Create GCP project in console.cloud.google.com."
        - "Enable: Google Classroom API, Google Forms API, People API."
        - "Create OAuth Client ID; configure consent screen."
        - "For Web app, include http://localhost in Authorized JS origins and Redirect URIs."
      license_notes:
        - "Rubrics create/update/delete require Education Plus for owner + API user."
        - "Add-On creation eligibility requires T&L Upgrade or Education Plus."
        - "SIS roster/grade exports require Instructional Upgrade or Education Plus."
      contact_sales_url: "https://edu.google.com/intl/ALL_us/contact/"

    - id: GC-CLASSROOM-COURSE
      title: "Create Google Classroom Course (for app access)"
      actions:
        - "Go to https://classroom.google.com → Create class."
        - "Fill all fields; copy Invite Link; have another Google user join as Student."

    - id: GITHUB-FORK
      title: "Fork & Prepare Repository"
      actions:
        - "Fork https://github.com/umgc/2025_fall to your account."
        - "Keep name '2025_fall'; uncheck 'Copy the developer branch only'."
        - "Select branch 'team_e' for build."
        - "To sync: switch to team_e → Sync fork → Update Branch."
      token:
        create_pat:
          path: "Settings → Developer settings → Personal access tokens → Tokens (classic)"
          scopes: ["admin:repo_hook"]
          expiry: "End of semester"
          store_securely: true

    - id: GIT-CLONE
      title: "Clone repo & checkout branch"
      commands:
        - "git clone <your fork https URL>"
        - "cd 2025_fall"
        - "git checkout team_e"
        - "# later updates:"
        - "git pull"

    - id: TF-INIT
      title: "Terraform Initial Creation"
      actions:
        - "Navigate to LearningLense2025/teamA → copy .envtemplate → .env"
        - "cd ../terraform (LearningLense2025/teamA/terraform or project /terraform per repo structure)"
      commands:
        - "terraform init"
        - "terraform apply -var \"github_token=<YOUR_PAT>\""
        - "# confirm by typing: yes"
        - "terraform show > terraformout.txt"
      parse_outputs:
        expected_keys:
          - "public_dns (two EC2-style URLs)"
          - "function_url"
          - "default_domain"
          - "display_name"

    - id: MOODLE-SSH
      title: "Obtain Moodle Credentials on EC2"
      commands:
        - "ssh -i ~/.ssh/moodle-key-pair.pem bitnami@<public_dns>"
        - "cat bitnami_credentials"
        - "exit"
      outputs:
        - "username/password for Moodle admin (teacher role)"

    - id: MOODLE-CONFIG
      title: "Configure Moodle & Install Plugins"
      actions:
        - "Open https://<public_dns>"
        - "Login with bitnami credentials (teacher)."
        - "Site administration → General → Advanced features: enable 'Web services' and 'Web services for mobile devices'; Save."
        - "Site administration → Server → Web services → Manage protocols: enable REST and SOAP; Save."
        - "Install 'Learning Lense' PHP plugin: Plugins → Install plugins → upload LearningLense2025/MoodlePlugin/learninglens.zip → follow prompts until success."
        - "(Optional) Install Adminer plugin: local_adminer_moodle45_2025021700.zip."

    - id: MOODLE-STUDENT
      title: "Create Moodle Student"
      actions:
        - "Site administration → Users → Accounts → Add a new user."
        - "Set username; Authentication = Manual accounts."
        - "Create password; set required name/email (email can be placeholder like mymail@edulense.com)."
        - "Create user; store credentials."

    - id: MOODLE-COURSE
      title: "Create Moodle Course & Enroll"
      actions:
        - "Courses → Add a new course."
        - "Set full name, short name, category, ID number."
        - "Visibility = Show."
        - "Start date in the past; end date in the future (post-semester)."
        - "Save and display."
        - "Course Administration → Participants → Enrol users → add student as 'Student' and confirm."
        - "Confirm 'Admin' is 'Teacher' by default."

    - id: DOTENV-FILL
      title: "Fill .env values (LearningLense2025/teamA/.env)"
      fields:
        - "openai_apikey | perplexity_api | grokKey (at least one)"
        - "MOODLE_USERNAME (admin/teacher or student account to auto-login)"
        - "MOODLE_URL = https://<public_dns>"
        - "GOOGLE_CLIENT_ID (if GC integration)"
        - "AI_LOGGING_URL = <function_url from Terraform outputs>"
      action: "Save file."

    - id: TF-FINALIZE
      title: "Re-run Terraform to push env to Amplify"
      commands:
        - "cd LearningLense2025/teamA/terraform"
        - "terraform apply -var \"github_token=<YOUR_PAT>\""
        - "# confirm: yes"

    - id: AMPLIFY-DEPLOY
      title: "Manually deploy Amplify app"
      actions:
        - "AWS Console → Amplify → find 'EduLenseApp' → select branch 'team_e'."
        - "Click 'Deploy' or 'Redeploy this version'."
        - "Navigate to https://<display_name>.<default_domain> (from Terraform outputs)."
        - "App should auto-login as MOODLE_USERNAME from .env."
        - "Use settings cog to sign out / switch user."
        - "Use LMS dropdown to switch LMS (defaults to Moodle if both configured)."
      warnings: ["WARN-AMPLIFY-FIRST-BUILD"]

  command_snippets:
    verify_installs:
      - "git --version"
      - "aws --version"
      - "wsl --help"
      - "docker --version"
      - "terraform --version"
    terraform:
      - "terraform init"
      - "terraform apply -var \"github_token=<YOUR_PAT>\""
      - "terraform show > terraformout.txt"
    ssh_moodle:
      - "ssh -i ~/.ssh/moodle-key-pair.pem bitnami@<public_dns>"
      - "cat bitnami_credentials"

  acceptance_criteria:
    - "Terraform applies succeed twice (initial + finalize) without errors."
    - "terraformout.txt contains public_dns (2), function_url, default_domain, display_name."
    - "Moodle reachable at https://<public_dns> and admin login works."
    - "Learning Lense plugin shows 'Success' on install page."
    - "Student user can log in; course exists and is in-progress; student enrolled."
    - "Amplify app deploys on branch team_e and is reachable at https://<display_name>.<default_domain>."
    - "App auto-login works as configured; LMS switcher visible."

  troubleshooting (sparse_placeholders):
    - symptom: "Amplify shows deployed but site 404s"
      checks:
        - "Wait for DNS to propagate; verify <display_name>.<default_domain> matches outputs."
        - "Redeploy branch team_e explicitly."
    - symptom: "Docker build fails on Windows"
      checks:
        - "Virtualization enabled in BIOS/UEFI."
        - "WSL2 installed and Docker set to use WSL2 backend."
    - symptom: "Terraform cannot access GitHub"
      checks:
        - "PAT token valid, not expired; includes admin:repo_hook."
    - symptom: "Moodle not reachable via HTTPS"
      checks:
        - "Security groups/ELB listeners created by Terraform; verify open ports 80/443."
    - symptom: "Classroom API calls fail with 403/insufficientPermissions"
      checks:
        - "Correct EDU SKU licenses assigned (Education Plus / T&L / Instructional)."
        - "OAuth consent screen published; correct scopes granted."

  outputs_to_record:
    - key: "public_dns"
      source: "terraformout.txt"
    - key: "function_url"
      source: "terraformout.txt"
    - key: "default_domain"
      source: "terraformout.txt"
    - key: "display_name"
      source: "terraformout.txt"
