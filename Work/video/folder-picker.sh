#!/bin/bash

# Folder Picker Helper Script
# Opens GUI file picker to select a folder
# Returns the selected folder path

select_folder_gui() {
    local selected_folder=""
    
    # Try different file picker tools in order of preference
    if command -v zenity &> /dev/null; then
        # GNOME/GTK file picker
        selected_folder=$(zenity --file-selection --directory --title="Select Video Folder" 2>/dev/null)
        
    elif command -v kdialog &> /dev/null; then
        # KDE file picker
        selected_folder=$(kdialog --getexistingdirectory "$HOME" --title="Select Video Folder" 2>/dev/null)
        
    elif command -v yad &> /dev/null; then
        # Yet Another Dialog (Zenity alternative)
        selected_folder=$(yad --file --directory --title="Select Video Folder" 2>/dev/null)
        
    elif command -v Xdialog &> /dev/null; then
        # Classic X dialog
        selected_folder=$(Xdialog --dselect "$HOME/" 0 0 2>/dev/null)
        
    else
        # Fallback: show available pickers
        echo "❌ No GUI file picker available" >&2
        echo "Install one of: zenity, kdialog, yad, or Xdialog" >&2
        return 1
    fi
    
    # Check if user cancelled or selected nothing
    if [ -z "$selected_folder" ]; then
        echo "❌ No folder selected" >&2
        return 1
    fi
    
    # Verify the selected path is a directory
    if [ ! -d "$selected_folder" ]; then
        echo "❌ Invalid folder: $selected_folder" >&2
        return 1
    fi
    
    echo "$selected_folder"
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    if result=$(select_folder_gui); then
        echo "Selected folder: $result"
        exit 0
    else
        exit 1
    fi
fi
