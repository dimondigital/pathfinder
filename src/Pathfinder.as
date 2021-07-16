package {

import flash.display.Sprite;

[SWF (backgroundColor="0x333333", width="550")]
public class Pathfinder extends Sprite
{
    private var _grid:PathGrid;
    private var _desc:McDesc;


        public function Pathfinder()
        {
            _grid = new PathGrid(stage, 20, 20, 200);
            _desc = new McDesc();
            addChild(_desc);
            addChild(_grid);
        }
}
}
