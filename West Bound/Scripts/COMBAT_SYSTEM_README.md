# Combat System Implementation Guide

## Overview

The combat system has been completely refactored to provide a robust, scalable solution with proper state management, respawning, and better code organization.

## Key Improvements

### 1. Global State Management (GLOBAL.gd)

- **Centralized player states**: Both players' health, direction, and alive status are tracked in a dictionary
- **Bullet tracking**: Uses unique IDs instead of arrays to prevent indexing errors
- **Constants**: All game constants (damage, max HP) are defined in one place
- **Helper functions**: `damage_player()`, `reset_player()`, and `get_player_health_percentage()`

### 2. Bullet System (Bullet.gd)

- **Ownership tracking**: Bullets know which player fired them
- **Collision exceptions**: Bullets can't hit their own owner
- **Lifetime limit**: Bullets auto-destroy after 5 seconds
- **Proper cleanup**: Uses unique ID system for reliable tracking

### 3. Player Scripts

- **PlayerScript.gd**: Updated to work with new system while maintaining backward compatibility
- **player_2.gd**: Now fully functional with shooting, pickup, and respawn
- **Player.gd**: New unified script that can be used for any number of players

### 4. Respawn System

- Players become semi-transparent when killed
- 3-second respawn timer (configurable)
- Automatic respawn at designated spawn points
- Items are dropped on death
- Health is fully restored on respawn

### 5. UI System (HealthUI.gd)

- Simple script to display player health
- Color-coded health indicators (green/yellow/red)
- Can be attached to any Label node

## How to Use

### Setting Up Players

1. **Using existing PlayerScene.tscn**:

   - The scene already works with the new system
   - Just need to set the `player_id` export variable in the inspector

2. **Using the new unified Player.gd**:

   ```gdscript
   # In your player scene, attach Player.gd
   # Set player_id to "P1" or "P2" in the inspector
   # Configure input map if using custom controls
   ```

3. **For Player 2 with existing setup**:
   - player2.tscn with player_2.gd now supports full combat

### Setting Up Spawn Points

Add Marker2D nodes to your level with appropriate groups:

```
SpawnP1 (Marker2D) - Add to group: "spawn_P1"
SpawnP2 (Marker2D) - Add to group: "spawn_P2"
```

### Adding Health UI

1. Create a Label node
2. Attach HealthUI.gd script
3. Set `player_id` property to "P1" or "P2"

### Test Scene

Load `Scenes/test_combat_system.tscn` to see a complete working example with:

- Two players with spawn points
- Health UI for both players
- Ground collision
- Two revolvers to pick up

## Input Mappings Required

Make sure your project has these input actions defined:

- P1: `P1_left`, `P1_right`, `P1_jump`, `P1_fire`, `P1_pickup`
- P2: `P2_left`, `P2_right`, `P2_jump`, `P2_fire`, `P2_pickup`

## Migration Notes

### From Old System

- Replace `Global.P1_HP` with `Global.player_states["P1"]["hp"]`
- Replace `Global.P1_direction` with `Global.player_states["P1"]["direction"]`
- Replace `Global.bullets_in_scene` array operations with `register_bullet()` and `unregister_bullet()`
- Update hurtbox groups from "Player1Hurtbox" to "P1_Hurtbox" format

### Backward Compatibility

- PlayerScript.gd has been updated to work with both old scenes and new system
- Default player_id is "P1" for compatibility
- Old scenes will work but won't have respawn functionality until spawn points are added

## Best Practices

1. **Always use spawn points**: Add spawn markers to ensure proper respawning
2. **Use constants**: Reference `Global.REVOLVER_DAMAGE` instead of hardcoding values
3. **Check player states**: Use `Global.player_states[player_id]` for all player data
4. **Consistent naming**: Use "P1", "P2" format for player IDs

## Debugging

- Bullets print hit information to console
- Players print HP when shooting
- Check `Global.player_states` in debugger to see current player states
- Ensure collision layers/masks are set correctly for bullets and hurtboxes
