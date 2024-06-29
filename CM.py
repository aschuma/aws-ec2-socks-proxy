#!/usr/bin/env python3

import os
import argparse
import logging

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def list_configurations(config_dir):
    """List all .ini configuration files in the specified directory."""
    try:
        return [f for f in os.listdir(config_dir) if f.endswith('.ini')]
    except FileNotFoundError:
        logging.error(f"Directory '{config_dir}' does not exist.")
        return []

def get_current_symlink(symlink_path):
    """Get the target of the symlink."""
    if os.path.islink(symlink_path):
        return os.readlink(symlink_path)
    return None

def update_symlink(symlink_path, new_target):
    """Update the symlink to point to the new target."""
    try:
        if os.path.exists(symlink_path):
            os.remove(symlink_path)
        os.symlink(new_target, symlink_path)
        logging.info(f"Symlink updated to point to {new_target}")
    except Exception as e:
        logging.error(f"Failed to update symlink: {e}")

def prompt_user_selection(configurations):
    """Prompt the user to select a configuration file from the list."""
    while True:
        try:
            choice = int(input("\nSelect the number of the configuration file you want to use: "))
            if 1 <= choice <= len(configurations):
                return configurations[choice - 1]
            else:
                raise ValueError
        except ValueError:
            print("Invalid selection. Please enter a number corresponding to the configuration file.")

def main(config_dir, symlink_path):
    setup_logging()

    print("AWSSOCKS Configuration Manager")
    print("==============================")

    configurations = list_configurations(config_dir)
    if not configurations:
        print("No configuration files found in the configs directory.")
        return

    current_target = get_current_symlink(symlink_path)

    print("Available configuration files:")
    for i, config in enumerate(configurations, 1):
        full_path = os.path.join(config_dir, config)
        if current_target and os.path.samefile(full_path, current_target):
            print(f"{i}. {config} (current)")
        else:
            print(f"{i}. {config}")

    selected_file = prompt_user_selection(configurations)
    new_target = os.path.join(config_dir, selected_file)
    update_symlink(symlink_path, new_target)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Manage configuration files via symlink.")
    parser.add_argument('--config-dir', type=str, default='configs', help="Directory containing configuration files.")
    parser.add_argument('--symlink-path', type=str, default='current-config.ini', help="Path to the symlink.")
    args = parser.parse_args()

    main(args.config_dir, args.symlink_path)

