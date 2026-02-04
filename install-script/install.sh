#!/bin/bash
#
# ClawdSquad Agent Installer
# One-command install for ClawdSquad agents
# Usage: curl -fsSL https://clawdsquad.com/install.sh | bash -s <agent-slug>
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLAWDSQUAD_API="https://clawdsquad.com/api/v1"
INSTALL_DIR="${HOME}/.clawdsquad"
OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
OPENCLAW_SKILLS="${HOME}/.openclaw/skills"

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

print_banner() {
    echo ""
    echo -e "${BLUE}🦞  ClawdSquad Agent Installer${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

check_dependencies() {
    local os=$(detect_os)
    
    log_info "Detecting operating system..."
    
    # Check for required tools
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warn "jq not found. Installing..."
        case $os in
            macos)
                if command -v brew &> /dev/null; then
                    brew install jq
                else
                    log_error "Homebrew not found. Please install jq manually."
                    exit 1
                fi
                ;;
            linux)
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update && sudo apt-get install -y jq
                elif command -v yum &> /dev/null; then
                    sudo yum install -y jq
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S jq
                else
                    log_error "Cannot install jq automatically. Please install manually."
                    exit 1
                fi
                ;;
            *)
                log_error "Cannot install jq on this OS. Please install manually."
                exit 1
                ;;
        esac
    fi
    
    log_success "Dependencies satisfied"
}

check_install_openclaw() {
    log_info "Checking OpenClaw installation..."
    
    if command -v openclaw &> /dev/null; then
        log_success "OpenClaw found: $(openclaw --version 2>/dev/null || echo 'installed')"
        return 0
    fi
    
    log_warn "OpenClaw not found. Installing..."
    
    local os=$(detect_os)
    
    case $os in
        macos)
            if command -v brew &> /dev/null; then
                log_info "Installing via Homebrew..."
                brew install openclaw
            else
                log_info "Installing via curl..."
                curl -fsSL https://openclaw.ai/install.sh | bash
            fi
            ;;
        linux)
            log_info "Installing via curl..."
            curl -fsSL https://openclaw.ai/install.sh | bash
            ;;
        *)
            log_error "Automatic installation not supported for your OS."
            log_info "Please install manually: https://openclaw.ai/docs/install"
            exit 1
            ;;
    esac
    
    # Verify installation
    if ! command -v openclaw &> /dev/null; then
        log_error "OpenClaw installation failed. Please install manually."
        exit 1
    fi
    
    log_success "OpenClaw installed successfully"
}

fetch_agent_info() {
    local agent_slug="$1"
    
    log_info "Fetching agent info: $agent_slug..."
    
    local response=$(curl -fsSL "${CLAWDSQUAD_API}/agents/${agent_slug}" 2>/dev/null || echo "")
    
    if [[ -z "$response" ]]; then
        log_error "Agent '$agent_slug' not found."
        log_info "Run 'curl clawdsquad.com | bash' to browse available agents."
        exit 1
    fi
    
    echo "$response"
}

download_agent() {
    local agent_slug="$1"
    local download_dir="$2"
    
    log_info "Downloading agent package..."
    
    local download_url="${CLAWDSQUAD_API}/agents/${agent_slug}/download"
    
    curl -fsSL "$download_url" -o "${download_dir}/agent.tar.gz" || {
        log_error "Failed to download agent package"
        exit 1
    }
    
    tar -xzf "${download_dir}/agent.tar.gz" -C "$download_dir" || {
        log_error "Failed to extract agent package"
        exit 1
    }
    
    rm "${download_dir}/agent.tar.gz"
    
    log_success "Agent downloaded and extracted"
}

setup_workspace() {
    local agent_dir="$1"
    local manifest="$2"
    
    local workspace=$(echo "$manifest" | jq -r '.workspace')
    workspace="${workspace/#\~/$HOME}"
    
    log_info "Setting up workspace: $workspace..."
    
    # Create workspace directory
    mkdir -p "$workspace"
    
    # Copy workspace files
    if [[ -d "${agent_dir}/workspace" ]]; then
        cp -r "${agent_dir}/workspace/." "$workspace/"
    fi
    
    log_success "Workspace created"
    echo "$workspace"
}

install_bundled_skills() {
    local agent_dir="$1"
    
    log_info "Installing bundled skills..."
    
    mkdir -p "$OPENCLAW_SKILLS"
    
    local skills_count=0
    
    if [[ -d "${agent_dir}/skills" ]]; then
        for skill_dir in "${agent_dir}/skills"/*/; do
            if [[ -d "$skill_dir" ]]; then
                local skill_name=$(basename "$skill_dir")
                cp -r "$skill_dir" "${OPENCLAW_SKILLS}/"
                ((skills_count++)) || true
                log_info "  Installed: $skill_name"
            fi
        done
    fi
    
    log_success "Installed $skills_count skill(s)"
}

merge_agent_config() {
    local agent_dir="$1"
    
    log_info "Configuring OpenClaw..."
    
    mkdir -p "$(dirname "$OPENCLAW_CONFIG")"
    
    local agent_config="${agent_dir}/agent.json"
    
    if [[ ! -f "$agent_config" ]]; then
        log_error "agent.json not found in package"
        exit 1
    fi
    
    if [[ -f "$OPENCLAW_CONFIG" ]]; then
        # Merge into existing config
        local temp_config=$(mktemp)
        jq --slurpfile agent "$agent_config" '.agents.list += [$agent[0]]' "$OPENCLAW_CONFIG" > "$temp_config"
        mv "$temp_config" "$OPENCLAW_CONFIG"
    else
        # Create new config
        jq -n --slurpfile agent "$agent_config" '{agents: {list: [$agent[0]]}}' > "$OPENCLAW_CONFIG"
    fi
    
    log_success "Agent configuration merged"
}

prompt_for_credentials() {
    local manifest="$1"
    
    log_info "Checking required credentials..."
    
    local channels=$(echo "$manifest" | jq -r '.channels[]' 2>/dev/null || echo "")
    
    # Check for Telegram
    if echo "$channels" | grep -q "telegram"; then
        if ! grep -q "TELEGRAM_BOT_TOKEN" "$OPENCLAW_CONFIG" 2>/dev/null; then
            echo ""
            log_warn "Telegram configuration required"
            echo "Get your bot token from @BotFather on Telegram"
            read -p "Enter Telegram bot token: " token
            
            # Add to config
            local temp_config=$(mktemp)
            jq --arg token "$token" '.env.TELEGRAM_BOT_TOKEN = $token' "$OPENCLAW_CONFIG" > "$temp_config"
            mv "$temp_config" "$OPENCLAW_CONFIG"
            log_success "Telegram token configured"
        fi
    fi
    
    # Check for Discord
    if echo "$channels" | grep -q "discord"; then
        if ! grep -q "DISCORD_BOT_TOKEN" "$OPENCLAW_CONFIG" 2>/dev/null; then
            echo ""
            log_warn "Discord configuration required"
            read -p "Enter Discord bot token: " token
            
            local temp_config=$(mktemp)
            jq --arg token "$token" '.env.DISCORD_BOT_TOKEN = $token' "$OPENCLAW_CONFIG" > "$temp_config"
            mv "$temp_config" "$OPENCLAW_CONFIG"
            log_success "Discord token configured"
        fi
    fi
}

start_gateway() {
    log_info "Starting OpenClaw gateway..."
    
    if pgrep -f "openclaw gateway" > /dev/null; then
        log_warn "Gateway already running. Restarting..."
        openclaw gateway stop 2>/dev/null || true
        sleep 2
    fi
    
    openclaw gateway start --daemon
    
    # Wait for gateway to be ready
    local retries=0
    while [[ $retries -lt 10 ]]; do
        if openclaw status &>/dev/null; then
            log_success "Gateway started successfully"
            return 0
        fi
        sleep 1
        ((retries++)) || true
    done
    
    log_warn "Gateway may still be starting..."
}

print_success() {
    local agent_name="$1"
    local emoji="$2"
    local workspace="$3"
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅  $emoji $agent_name is LIVE!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "📍 Workspace: $workspace"
    echo "⚙️  Config:    $OPENCLAW_CONFIG"
    echo "📊 Status:    openclaw status"
    echo "📝 Logs:      openclaw logs --follow"
    echo ""
    echo "Need help? Visit: https://clawdsquad.com/help"
    echo ""
}

# Main installation flow
main() {
    local agent_slug="${1:-}"
    
    print_banner
    
    # If no agent specified, show interactive menu
    if [[ -z "$agent_slug" ]]; then
        log_info "No agent specified. Starting interactive mode..."
        log_info "(Coming soon: Browse agents at https://clawdsquad.com)"
        echo ""
        echo "Usage: curl -fsSL https://clawdsquad.com/install.sh | bash -s <agent-slug>"
        echo ""
        echo "Example agents:"
        echo "  - code-ninja      (Software development)"
        echo "  - growth-hacker   (Digital marketing)"
        echo "  - deal-maker      (Sales & outreach)"
        echo "  - insight-miner   (Data analysis)"
        echo "  - content-king    (Content creation)"
        echo "  - chaos-agent     (Chaos & entertainment)"
        exit 1
    fi
    
    # Create temp directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Installation steps
    check_dependencies
    check_install_openclaw
    
    local manifest=$(fetch_agent_info "$agent_slug")
    local agent_name=$(echo "$manifest" | jq -r '.name')
    local emoji=$(echo "$manifest" | jq -r '.emoji')
    
    download_agent "$agent_slug" "$temp_dir"
    
    local workspace=$(setup_workspace "$temp_dir" "$manifest")
    install_bundled_skills "$temp_dir"
    merge_agent_config "$temp_dir"
    prompt_for_credentials "$manifest"
    start_gateway
    
    print_success "$agent_name" "$emoji" "$workspace"
}

# Run main function
main "$@"
