package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
        public function new()
        {
                super();
                addChild(new FlxGame(960, 540, PlayState, 1, 60, 60, true, false));
        }
}
