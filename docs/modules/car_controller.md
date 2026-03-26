# Car Controller Module

## Files
- `src/car/car_controller.gd` - CharacterBody2D player car with arcade drift physics
- `src/car/car_stats.gd` - Resource holding base stats, loaded from JSON
- `src/car/drift_state_machine.gd` - 4-stage drift system (NONE->CHARGING_1->CHARGING_2->READY)
- `src/car/nitro_system.gd` - Nitro gauge accumulation/drain/boost
- `src/car/weapon_mount.gd` - Single weapon slot
- `src/car/weapon_mount_manager.gd` - Manages 4-6 weapon slots

## Drift Physics
Core mechanic: velocity lerp with traction values.
- Normal: `velocity = velocity.lerp(desired, 0.75)` (responsive)
- Drifting: `velocity = velocity.lerp(desired, 0.05)` (slidey)
- Drift starts when: holding drift key + speed > slip_speed + steering input
- Auto-nitro on drift release at READY stage

## Key Parameters (from cars.json)
max_speed=500, boost_speed=750, engine_power=400, steer_angle=15,
slip_speed=300, traction_normal=0.75, traction_drift=0.05

## Tests
test_car_controller.gd, test_car_stats.gd, test_drift_state_machine.gd, test_nitro_system.gd
