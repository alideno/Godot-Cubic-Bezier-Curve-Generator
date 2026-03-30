# Cubic Bezier Curve Generator #

Creates a cubic bezier curve given four points. If you come across this and intent to use it in your project first of all thank you. 
Secondly, I didn't add a way to easily add textures as it is out of the scope of the project. Thanks to Godot the curve has a solid white color when there is no textures.

I tested this on an office laptop that can run low end games (and runs them barely when the charger is unplugged) and my desktop

I might add other curve types as well, since the basic algoritm for point creation and selection would be roughly the same. I also consider creating a 3D versions if I have the time and motivation.

## How to Use ##

1. Put a cubic bezier curve object in the scene
2. Place and assign 4 markers to the curve
3. If you need to move one of the points dynamically, the object automatically recreates the curve




Earliest version of the curve
![Old curves in action](curve.gif)

## Update Log ##
The updates are in chronological order, going from oldest to newest.

- Changed from creating bazillion texture rectangles to one mesh
- Changed from creating bazillion collision shapes for bazillion texture rectangles to creating one collision polygon
- Switched from PRIMITIVE_TRIANGLE to PRIMITIVE_TRIANGLE_STRIP for mesh triangulation
- Fixed an oversight where every vertex was created twice

- Vertices with super small angles between them are eliminated
This changed doubled the fps count but the curve now looks like an accordion. Refer to the two screenshots in the [Board of Pain™](BoardOfPain.png).
- Fixed the accordion glitch
- Fixed memory leaks
- Currently fully working with no fps drops
