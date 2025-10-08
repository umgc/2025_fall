#!/bin/bash
# Moodle Setup Script for EduLense Deployment
# This script runs on EC2 instance startup to configure Moodle

set -e

# Variables
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"

# Update system packages
sudo apt-get update -y

# Install additional packages if needed
sudo apt-get install -y curl wget unzip

# Wait for Moodle to be fully initialized
sleep 60

# Enable web services in Moodle configuration
sudo /opt/bitnami/moodle/bin/moodle-cli.php --config-set enablewebservices 1 || true
sudo /opt/bitnami/moodle/bin/moodle-cli.php --config-set enablemobilewebservice 1 || true

# Set up Moodle cron job
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/bitnami/php/bin/php /opt/bitnami/moodle/admin/cli/cron.php >/dev/null 2>&1") | crontab -

# Create EduLense configuration marker
echo "EduLense-$PROJECT_NAME-$ENVIRONMENT-$(date)" | sudo tee /opt/bitnami/moodle/edulense-config.txt

# Set proper permissions for plugin installation
sudo chmod -R 775 /opt/bitnami/moodle/local/
sudo chown -R bitnami:daemon /opt/bitnami/moodle/local/
sudo chmod -R 775 /opt/bitnami/moodle/
sudo chown -R bitnami:daemon /opt/bitnami/moodle/

# Restart Apache to apply changes
sudo /opt/bitnami/ctlscript.sh restart apache