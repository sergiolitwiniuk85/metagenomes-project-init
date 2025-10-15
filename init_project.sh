#!/usr/bin/env bash
# ============================================================
#  Script: init_project.sh
#  Descripción: Inicializa y gestiona proyectos Snakemake
#               para análisis metagenómicos.
#  Autor: Sergio Litwiniuk
#  Versión: 1.3.0
#  Fecha: $(date +"%Y-%m-%d")
# ============================================================

set -euo pipefail

show_help() {
cat << 'EOF'
init_project.sh — Snakemake project initializer & manager
Version: 1.3.0
Author : Sergio Litwiniuk <sergiolitwiniuk@bio.dev>

Description:
  init_project.sh is a Bash utility to create and manage standardized,
  timestamped project directories for Snakemake-based metagenomic analyses.

  It provides:
    • Automatic directory creation (Proyecto_Metagenomas_YYYYMMDD_HHMMSS)
    • Tag assignment via extended attributes (user.tags)
    • Project listing with tags for quick overview

Usage:
  init_project.sh [command] [options]

Commands:
  new               Initialize a new Snakemake project
  list              List all projects in the current (or specified) path
  help, -h, --help  Show this help message

Options:
  --tag <value>     Assign a tag (stored as user.tags) to the project
  --path <path>     Specify custom directory (default: current working directory)

Examples:
  Create new project:
    init_project.sh new --tag "araucaria1"

  List projects in current directory:
    init_project.sh list

  List projects in custom path:
    init_project.sh list --path /mnt/data/metagenomes/

  Verify tag:
    getfattr -n user.tags Proyecto_Metagenomas_20251015_102412/
EOF
}

COMMAND="${1:-}"
TAG=""
CUSTOM_PATH="$(pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        new)
            COMMAND="new"
            shift
            ;;
        list)
            COMMAND="list"
            shift
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --path)
            CUSTOM_PATH="$2"
            shift 2
            ;;
        -h|--help|help|man)
            show_help
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# ============================================================
# FUNCIONES AUXILIARES
# ============================================================

create_project() {
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")   # ← incluye hora, minutos y segundos
    local PROJECT_DIR="${CUSTOM_PATH}/Proyecto_Metagenomas_${TIMESTAMP}"

    echo "🔧 Creating Snakemake project: ${PROJECT_DIR}"
    mkdir -p "${PROJECT_DIR}"/{data,1_Filtered,2_Assembly,3_Annotation,4_Post_Processing,logs/{filter,assembly,annotation},scripts}

    if [[ -n "$TAG" ]]; then
        echo "🏷️  Setting folder tag: user.tags=\"${TAG}\""
        setfattr -n user.tags -v "${TAG}" "${PROJECT_DIR}"
    fi

    cat > "${PROJECT_DIR}/config.yaml" << 'EOF'
# --------------------------
# Project configuration file
# --------------------------
SAMPLES: ["sample1", "sample2"]
N_THREADS: 8
ASSEMBLY_TOOL: "megahit"
EGGNOG_DB: "/path/to/eggnog_db"
EOF

    cat > "${PROJECT_DIR}/Snakefile" << 'EOF'
# Snakefile (Simplified Template)
import os
from snakemake.io import expand

configfile: "config.yaml"

SAMPLES = config["SAMPLES"]
THREADS = config["N_THREADS"]
ASSEMBLY = config["ASSEMBLY_TOOL"]

rule all:
    input:
        expand("4_Post_Processing/{sample}_EC_counts.tsv", sample=SAMPLES)
EOF

    echo "✅ Project successfully initialized at: ${PROJECT_DIR}"
    if [[ -n "$TAG" ]]; then
        echo "ℹ️  Tag applied: $(getfattr -n user.tags --only-values "${PROJECT_DIR}")"
    fi
}

list_projects() {
    local TARGET_PATH="$CUSTOM_PATH"

    echo -e "Folder\tTag"
    echo "---------------------------------------------"

    for dir in "${TARGET_PATH}"/Proyecto_*; do
        if [[ -d "$dir" ]]; then
            tag=$(getfattr -n user.tags --only-values "$dir" 2>/dev/null || echo "-")
            folder=$(basename "$dir")
            printf "%-40s %s\n" "$folder" "$tag"
        fi
    done
}

# ============================================================
# EJECUCIÓN DE COMANDOS
# ============================================================
case "$COMMAND" in
    new)
        create_project
        ;;
    list)
        list_projects
        ;;
    *)
        echo "❌ Unknown or missing command. Use 'init_project.sh --help' for usage."
        exit 1
        ;;
esac
