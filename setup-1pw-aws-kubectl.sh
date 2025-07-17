#! /bin/bash

# If --uninstall is passed, uninstall the AWS CLI, 1Password CLI, and the 1Password AWS plugin
if [ "$1" = "--uninstall" ]; then
  echo ""
  echo "♻️ Uninstalling AWS CLI..."
  brew uninstall awscli
  echo "♻️ Uninstalling 1Password CLI..."
  brew uninstall 1password-cli
  echo "♻️ Uninstalling kubectl..."
  brew uninstall kubernetes-cli

  echo ""
  echo "✅ Uninstallation complete"
  echo ""
  echo "Manual steps are required to clean up:"
  echo "Remove the ~/.aws directory: rm -rf ~/.aws"
  echo "Remove the ~/.kube directory: rm -rf ~/.kube"
  echo "Remove the ~/.config/op directory: rm -rf ~/.config/op"
  echo "Clean up the ~/.zshrc file: remove the aws and kubectl plugins and the 'source ~/.config/op/plugins.sh' line"

  exit 0
fi

set -e

# Used to set up the base profile (common profile for all roles)
setup_aws_base_profile() {
  echo ""
  echo "ℹ️ Setting up the base profile (common profile for all roles)"

  # If we already have a base profile, skip this step
  if grep -q "\[profile base\]" ~/.aws/config; then
      echo "ℹ️ Base profile already exists"
      return
  fi

  # For the base profile, we will need user_arn and mfa_serial (if MFA is enabled)
  echo ""
  echo "ℹ️ You can find the following information in AWS Console > IAM > Security Credentials"
  read -p "Enter the User ARN: " user_arn
  read -p "Enter the MFA Identifier (leave empty if MFA is not enabled): " mfa_serial

  # Add the profile to ~/.aws/config
  echo "" >> ~/.aws/config
  echo "[profile base]" >> ~/.aws/config
  echo "output = json" >> ~/.aws/config
  echo "user_arn = $user_arn" >> ~/.aws/config
  echo "mfa_serial = $mfa_serial" >> ~/.aws/config
}

# Used to set up a new AWS role profile
setup_aws_role_profiles() {
  # Ask user if they want to set up a new AWS role profile
  echo ""
  read -p "Do you want to set up a new AWS role profile? (y/n) " setup_new_role_profile
  while [ "$setup_new_role_profile" = "y" ]; do
    echo ""
    echo "ℹ️ Setting up a new AWS role profile..."

    # Ask user for the role name
    echo ""
    echo "ℹ️ Sign into AWS Console with the role you want to set up. You can then find the following information in AWS Console > IAM > Roles > Role Name"
    read -p "Enter the profile name: " profile_name
    read -p "Enter the region (where resources are located): " region
    read -p "Enter the Role ARN: " role_arn
    read -p "Enter the session name (any name you want): " session_name

    # Add the profile to ~/.aws/config
    echo "" >> ~/.aws/config
    echo "[profile $profile_name]" >> ~/.aws/config
    echo "source_profile = base" >> ~/.aws/config
    echo "region = $region" >> ~/.aws/config
    echo "role_arn = $role_arn" >> ~/.aws/config
    echo "session_name = $session_name" >> ~/.aws/config

    # Ask user if they want to set up a new AWS role profile
    echo ""
    read -p "Do you want to set up a new AWS role profile? (y/n) " setup_new_role_profile
  done
}

setup_1password_cli() {
  # Install 1Password CLI
  echo ""
  echo "ℹ️ Installing 1Password CLI..."
  brew install 1password-cli

  # Ask the user to enable the 1Password CLI integration
  echo ""
  echo "⚠️ Make sure you have enabled the 1Password CLI integration in 1Password"
  echo "You can do this following these instructions: https://developer.1password.com/docs/cli/get-started/#step-2-turn-on-the-1password-desktop-app-integration"
  read -p "Press [Enter] to continue..."

  # Sign in to 1Password
  echo ""
  echo "ℹ️ Signing in to 1Password..."
  eval $(op signin)
}

setup_aws_cli() {
  # Install AWS CLI
  echo ""
  echo "ℹ️ Installing AWS CLI..."
  brew install awscli

  # Initialize AWS CLI
  echo ""
  echo "⚠️ When initializing the AWS CLI, you can leave empty everything, except for the region"
  echo "ℹ️ Initializing AWS CLI... "
  aws configure

  # Check that the ~/.aws/config file exists
  if [ ! -f ~/.aws/config ]; then
      echo "❌ ~/.aws/config not found"
      exit 1
  fi

  # Check that the ~/.aws/config contains the default profile
  if ! grep -q "\[default\]" ~/.aws/config; then
      echo "❌ ~/.aws/config does not contain the default profile"
      echo "Provide at least the region when the AWS CLI is initialized"
      exit 1
  fi

  # Make sure a default region is set in ~/.aws/config
  if ! grep -q "region" ~/.aws/config; then
      echo "❌ ~/.aws/config does not contain the default region"
      echo "Provide the region when the AWS CLI is initialized"
      exit 1
  fi
}

setup_1password_aws_plugin() {
  # Prompt user to add AWS access key and secret access key to 1Password
  echo ""
  echo "⚠️ Make sure you have the AWS access key and secret access key stored in 1Password"
  echo "You can do this following these instructions: https://developer.1password.com/docs/cli/shell-plugins/aws/#step-1-create-and-save-an-aws-access-key"
  read -p "Press [Enter] to continue..."

  # Initialize the 1Password AWS plugin
  echo ""
  echo "⚠️ We will now install the 1Password AWS plugin. This will ask you to select the location of the AWS Keys in 1Password"
  echo "ℹ️ Initializing the 1Password AWS plugin..."
  op plugin init aws

  # Update ~/.zshrc to include the 1Password AWS plugin
  echo ""
  echo "ℹ️ Updating ~/.zshrc..."
  if ! grep -q "source $HOME/.config/op/plugins.sh" ~/.zshrc; then
      echo "" >> ~/.zshrc
      echo "source $HOME/.config/op/plugins.sh" >> ~/.zshrc
  else
      echo "~/.zshrc already contains the 1Password AWS plugin"
  fi
}

setup_aws_zsh_plugin() {
  # Set up aws ZSH plugin
  echo ""
  echo "ℹ️ Setting up aws ZSH plugin..."
  if ! grep -q "plugins=(.*aws.*)" ~/.zshrc; then
      sed -i '' 's/^plugins=(\(.*\))/plugins=(\1 aws)/' ~/.zshrc
  fi
}

instructions_to_test_aws_setup() {
  # Find the first non-base profile in ~/.aws/config (ie. [profile *] but not [profile base])
  first_non_base_profile=$(grep '^\[profile ' ~/.aws/config | sed '/^\[profile base\]/d' | sed 's/^\[profile \(.*\)\]/\1/' | head -n 1)

  echo ""
  echo "⚠️ AWS is now set up with 1Password. Open a new terminal and run the following to test:"
  echo "asp $first_non_base_profile"
  echo "aws sts get-caller-identity"
  echo ""
  echo "This should return the user ARN of the role you are assuming"
  read -p "Press [Enter] to continue..."
}

setup_kubectl() {
  # Install kubectl
  echo ""
  echo "ℹ️ Installing kubectl..."
  brew install kubernetes-cli

  # Install kubectl plugin for zsh
  echo ""
  echo "ℹ️ Installing kubectl plugin for zsh..."
  if ! grep -q "plugins=(.*kubectl.*)" ~/.zshrc; then
      sed -i '' 's/^plugins=(\(.*\))/plugins=(\1 kubectl)/' ~/.zshrc
  fi
}

kubectl_instructions() {
  echo ""
  echo "⚠️ To set up the kubectl contexts, you need to run the following command for each profile (cluster) you have in EKS"
  echo "First, switch to the profile you want to set up the context for"
  echo "asp <profile_name>"
  echo "Then, run the following command to set up the context"
  echo "aws eks update-kubeconfig --name <cluster_name>"
  echo ""
  echo "Repeat this for each cluster you have in EKS"
  read -p "Press [Enter] to continue..."

  echo ""
  echo "⚠️ In the end, you should have a ~/.kube/config file with the contexts for each cluster you have in EKS"
  echo "To integrate the authentication with 1Password, you need to use the "op plugin run" command for the users"
  echo ""
  echo "This is an example of a full ~/.kube/config file with the "dev" and "prod" contexts:"
  echo "apiVersion: v1
kind: Config
preferences: {}
current-context: dev
contexts:
- context:
    cluster: dev-cluster
    user: dev-user
  name: dev
- context:
    cluster: prod-cluster
    user: prod-user
  name: prod
clusters:
- cluster:
    certificate-authority-data: <REDACTED>
    server: <REDACTED>
  name: dev-cluster
- cluster:
    certificate-authority-data: <REDACTED>
    server: <REDACTED>
  name: prod-cluster
users:
- name: dev-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - plugin
      - run
      - --
      - aws
      - eks
      - get-token
      - --cluster-name
      - <CLUSTER_NAME>
      - --output
      - json
      command: op
      env: null
      interactiveMode: IfAvailable
      provideClusterInfo: false
- name: prod-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - plugin
      - run
      - --
      - aws
      - eks
      - get-token
      - --cluster-name
      - <CLUSTER_NAME>
      - --output
      - json
      command: op
      env: null
      interactiveMode: IfAvailable
      provideClusterInfo: false"
  read -p "Press [Enter] to continue (👆 first read above)..."
}

instructions_usage() {
  echo ""
  echo "--------------------------------"
  echo "✅ We are done"
  echo "You can now use the following commands to test the setup:"
  echo "source ~/.zshrc"
  echo "asp <profile_name>"
  echo "kubectl config use-context <context_name_for_profile>"
  echo "kubectl get ns"
}

# Run the setup
setup_aws_cli
setup_1password_cli
setup_1password_aws_plugin
setup_aws_base_profile
setup_aws_role_profiles
setup_aws_zsh_plugin
instructions_to_test_aws_setup
setup_kubectl
kubectl_instructions
instructions_usage