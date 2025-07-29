# IntelliJ Classic Key Bindings for Xcode - Installation Guide

## Installation Steps

1. **Copy the key bindings file to Xcode's KeyBindings directory:**
   ```bash
   cp IntelliJ-Classic.idekeybindings ~/Library/Developer/Xcode/UserData/KeyBindings/
   ```

2. **Restart Xcode** (completely quit and reopen)

3. **Select the key bindings:**
   - Open Xcode
   - Go to `Xcode → Preferences → Key Bindings`
   - Select "IntelliJ Classic" from the dropdown menu

## Key Mapping Reference

### Essential Navigation
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Go to Declaration | Cmd+B | Cmd+B |
| Find in Path | Cmd+Shift+F | Cmd+Shift+F |
| Replace in Path | Cmd+Shift+R | Cmd+Shift+R |
| Quick Open (File) | Cmd+Shift+O | Cmd+Shift+O |
| File Structure | Cmd+F12 | Cmd+F12 |
| Recent Files | Cmd+E | Cmd+Shift+E |
| Navigate Back | Cmd+[ | Cmd+[ |
| Navigate Forward | Cmd+] | Cmd+] |
| Go to Line | Cmd+G | Cmd+G |

### Code Editing
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Code Completion | Ctrl+Space | Ctrl+Space |
| Duplicate Line | Cmd+D | Cmd+D |
| Delete Line | Cmd+Y | Cmd+Y |
| Comment Line | Cmd+/ | Cmd+/ |
| Move Line Up | Alt+Shift+↑ | Alt+Shift+↑ |
| Move Line Down | Alt+Shift+↓ | Alt+Shift+↓ |
| Reformat Code | Cmd+Alt+L | Cmd+Alt+L |
| Quick Fix | Alt+Enter | Alt+Enter |

### Refactoring
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Rename | Shift+F6 | Shift+F6 |
| Extract Method | Cmd+Alt+M | Cmd+Alt+M |
| Extract Variable | Cmd+Alt+V | Cmd+Alt+V |
| Find Usages | Cmd+Alt+F7 | Cmd+Alt+F7 |

### Build & Run
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Build | Cmd+F9 | Cmd+F9 |
| Run | Ctrl+R | Ctrl+R |
| Debug | Ctrl+D | Ctrl+D |
| Stop | Cmd+F2 | Cmd+F2 |

### Debugging
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Toggle Breakpoint | Cmd+F8 | Cmd+F8 |
| Step Over | F8 | F8 |
| Step Into | F7 | F7 |
| Step Out | Shift+F8 | Shift+F8 |
| Resume | F9 | F9 |

### Search
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Find | Cmd+F | Cmd+F |
| Find Next | F3 | F3 |
| Find Previous | Shift+F3 | Shift+F3 |
| Find in Selection | Cmd+F3 | Cmd+F3 |

### View Management
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Project View | Cmd+1 | Cmd+1 |
| Debug View | Cmd+8 | Cmd+8 |
| Version Control | Cmd+9 | Cmd+9 |
| Terminal | Alt+F12 | Alt+F12 |
| Hide All Tool Windows | Cmd+Shift+F12 | Cmd+Shift+F12 |

### Code Generation
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Generate | Cmd+N | Cmd+N |
| Override Methods | Ctrl+O | Ctrl+O |
| Implement Methods | Ctrl+I | Ctrl+I |

### Version Control
| Action | IntelliJ Shortcut | Xcode Mapping |
|--------|------------------|---------------|
| Commit | Cmd+K | Cmd+K |
| Push | Cmd+Shift+K | Cmd+Shift+K |
| Pull/Update | Cmd+T | Cmd+Alt+K |

## Notes

- Some IntelliJ shortcuts may conflict with macOS system shortcuts
- Not all IntelliJ features have direct Xcode equivalents
- You can further customize these bindings in Xcode's Key Bindings preferences
- To revert to default Xcode bindings, select "Default" from the dropdown

## Troubleshooting

If the key bindings don't appear:
1. Ensure the file is in the correct directory
2. Check file permissions: `chmod 644 ~/Library/Developer/Xcode/UserData/KeyBindings/IntelliJ-Classic.idekeybindings`
3. Try creating the KeyBindings directory if it doesn't exist: `mkdir -p ~/Library/Developer/Xcode/UserData/KeyBindings/`