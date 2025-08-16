#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Load utilities (logging, shell-detection, cleanup)
########################################
source "$(dirname "$0")/../../env_utils.sh"
init_logging
detect_source_file
ensure_env_dir

########################################
# LOCAL DIRECTORIES TO STORE ENVIRONMENT SCRIPTS
########################################
LANGGRAPH_ENV_FILE="$ENVIRONMENT_DIR/.langgraph"

# Function to install LangGraph in a virtual environment
install_langgraph() {
    log "Setting up LangGraph installation..."
    
    # Check if Python is available
    if ! command -v python3 &> /dev/null; then
        err "Python3 is not installed. Please install Python first."
        exit 1
    fi
    
    # Create virtual environment for LangGraph
    local venv_dir="$HOME/.langgraph-venv"
    if [ ! -d "$venv_dir" ]; then
        log "Creating virtual environment for LangGraph..."
        python3 -m venv "$venv_dir"
    else
        log "Virtual environment already exists at $venv_dir"
    fi
    
    # Activate virtual environment and install LangGraph
    log "Installing LangGraph and related packages..."
    source "$venv_dir/bin/activate"
    pip install --upgrade pip
    pip install langgraph langgraph-checkpoint
    pip install langchain langchain-core langchain-community
    pip install langsmith
    deactivate
    
    # Create environment file
    if [ ! -f "$LANGGRAPH_ENV_FILE" ]; then
        touch "$LANGGRAPH_ENV_FILE"
    fi
    
    cat > "$LANGGRAPH_ENV_FILE" << EOF
# LangGraph Environment Configuration
export LANGGRAPH_VENV="$venv_dir"

# Function to activate LangGraph environment
activate_langgraph() {
    source "\$LANGGRAPH_VENV/bin/activate"
    echo "LangGraph environment activated"
}

# Function to deactivate LangGraph environment
deactivate_langgraph() {
    deactivate
    echo "LangGraph environment deactivated"
}
EOF
    
    log "LangGraph installed successfully in virtual environment: $venv_dir"
}

# Function to install LangGraph Studio (development environment)
install_langgraph_studio() {
    local venv_dir="$HOME/.langgraph-venv"
    if [ ! -d "$venv_dir" ]; then
        err "LangGraph virtual environment not found. Please install LangGraph first."
        exit 1
    fi
    
    log "Installing LangGraph Studio and development tools..."
    source "$venv_dir/bin/activate"
    
    # Install development and visualization tools
    pip install langgraph-studio
    pip install jupyter jupyterlab
    pip install matplotlib seaborn plotly
    pip install streamlit gradio
    
    deactivate
    log "LangGraph Studio and development tools installed successfully"
}

# Function to install additional LangGraph integrations
install_langgraph_integrations() {
    local venv_dir="$HOME/.langgraph-venv"
    if [ ! -d "$venv_dir" ]; then
        err "LangGraph virtual environment not found. Please install LangGraph first."
        exit 1
    fi
    
    log "Installing additional LangGraph integrations..."
    source "$venv_dir/bin/activate"
    
    # Database checkpointers
    pip install langgraph-checkpoint-sqlite langgraph-checkpoint-postgres
    
    # Additional LangChain integrations for graphs
    pip install langchain-openai langchain-anthropic
    
    # Graph visualization
    pip install graphviz pydot networkx
    
    # Memory and state management
    pip install redis
    
    deactivate
    log "Additional LangGraph integrations installed successfully"
}

# Function to update LangGraph packages
update_langgraph() {
    local venv_dir="$HOME/.langgraph-venv"
    if [ ! -d "$venv_dir" ]; then
        err "LangGraph virtual environment not found. Please install LangGraph first."
        exit 1
    fi
    
    log "Updating LangGraph packages..."
    source "$venv_dir/bin/activate"
    pip install --upgrade langgraph langgraph-checkpoint
    pip install --upgrade langchain langchain-core langchain-community
    pip install --upgrade langsmith
    deactivate
    log "LangGraph packages updated successfully"
}

# Function to show LangGraph installation info
show_langgraph_info() {
    local venv_dir="$HOME/.langgraph-venv"
    if [ ! -d "$venv_dir" ]; then
        err "LangGraph virtual environment not found."
        exit 1
    fi
    
    log "LangGraph Installation Information:"
    echo "Virtual Environment: $venv_dir"
    echo "Environment File: $LANGGRAPH_ENV_FILE"
    echo ""
    echo "To activate LangGraph environment:"
    echo "  source $LANGGRAPH_ENV_FILE && activate_langgraph"
    echo ""
    echo "To start Jupyter Lab:"
    echo "  activate_langgraph && jupyter lab"
    echo ""
    source "$venv_dir/bin/activate"
    echo "Installed packages:"
    pip list | grep -E "(langgraph|langchain)" || echo "No LangGraph packages found"
    deactivate
}

# Function to create sample LangGraph project
create_sample_project() {
    local venv_dir="$HOME/.langgraph-venv"
    if [ ! -d "$venv_dir" ]; then
        err "LangGraph virtual environment not found. Please install LangGraph first."
        exit 1
    fi
    
    local project_dir="$HOME/langgraph-projects"
    if [ ! -d "$project_dir" ]; then
        mkdir -p "$project_dir"
    fi
    
    log "Creating sample LangGraph project..."
    
    cat > "$project_dir/simple_graph.py" << 'EOF'
#!/usr/bin/env python3
"""
Simple LangGraph example - A basic chatbot with memory
"""

from typing import TypedDict, Annotated
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langchain_core.messages import BaseMessage

class State(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]

def chatbot(state: State):
    # This is a simple echo bot for demonstration
    last_message = state["messages"][-1]
    return {"messages": [f"Echo: {last_message.content}"]}

# Build the graph
graph_builder = StateGraph(State)
graph_builder.add_node("chatbot", chatbot)
graph_builder.add_edge(START, "chatbot")
graph_builder.add_edge("chatbot", END)

graph = graph_builder.compile()

if __name__ == "__main__":
    # Test the graph
    from langchain_core.messages import HumanMessage
    
    result = graph.invoke({
        "messages": [HumanMessage(content="Hello, LangGraph!")]
    })
    
    print("Graph output:", result["messages"][-1].content)
EOF
    
    echo "Sample project created at: $project_dir/simple_graph.py"
    echo "To run: cd $project_dir && activate_langgraph && python simple_graph.py"
}

# Ensure $LANGGRAPH_ENV_FILE is sourced in $SOURCE_FILE
marker="source $LANGGRAPH_ENV_FILE"
if [ -f "$LANGGRAPH_ENV_FILE" ]; then
    if ! grep -Fq "$marker" "$SOURCE_FILE"; then
        echo "$marker" >> "$SOURCE_FILE"
        log "Added LangGraph env script to $SOURCE_FILE. Please restart your shell or run: source $SOURCE_FILE"
    fi
fi

# Menu for managing LangGraph
info "Select an option:"
info "1) Install LangGraph"
info "2) Install LangGraph Studio (development tools)"
info "3) Install additional LangGraph integrations"
info "4) Update LangGraph packages"
info "5) Show LangGraph installation info"
info "6) Create sample LangGraph project"
info "7) Exit"

prompt "Enter your choice: "
read -r choice

case $choice in
    1) 
        enable_command_tracing
        install_langgraph
        ;;
    2) 
        enable_command_tracing
        install_langgraph_studio
        ;;
    3) 
        enable_command_tracing
        install_langgraph_integrations
        ;;
    4) 
        enable_command_tracing
        update_langgraph
        ;;
    5) show_langgraph_info ;;
    6) create_sample_project ;;
    7) exit 0 ;;
    *) err "Invalid option!" ;;
esac

finalize_logging