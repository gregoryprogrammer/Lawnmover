package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

import flixel.ui.FlxButton;

typedef Choice = {
        var button:FlxSprite;
        var col:Int;
        var row:Int;
}

class Choices extends FlxGroup
{
        public static inline var BUTTON_WIDTH = 80;
        public static inline var BUTTON_HEIGHT = 20;
        public static inline var FRAME = 8;
        public static inline var GAP = 4;

        public var position(default, set):FlxPoint;

        var m_buttons:Array<Choice>;
        var m_background:FlxSprite;
        var m_mini_frame:FlxSprite;
        var m_callback:Void->Void;

        var m_col = 0;
        var m_row = 0;

        public function new():Void
        {
                super();

                m_buttons = new Array<Choice>();

                m_background = new FlxSprite();
                add(m_background);

                position = new FlxPoint(0, 0);
        }

        override public function update(_elapsed:Float):Void
        {
                super.update(_elapsed);

                if (m_mini_frame != null) {
                        m_mini_frame.x = this.position.x + FRAME + m_col * BUTTON_WIDTH + m_col * GAP;
                        m_mini_frame.y = this.position.y + FRAME + m_row * BUTTON_HEIGHT + m_row * GAP;
                }
        }

        public function center_on_screen():Void
        {
                var x = (FlxG.width - m_background.width) / 2;
                var y = (FlxG.height - m_background.height) / 2;

                position = new FlxPoint(x, y);
        }

        public function set_position(_position:FlxPoint):FlxPoint
        {
                this.position = _position;

                m_background.x = _position.x;
                m_background.y = _position.y;

                for (i in 0...m_buttons.length) {
                        var choice = m_buttons[i];
                        var button = choice.button;

                        button.x = this.position.x + FRAME + choice.col * BUTTON_WIDTH + choice.col * GAP;
                        button.y = this.position.y + FRAME + choice.row * BUTTON_HEIGHT + choice.row * GAP;
                }

                return this.position;
        }

        public function add_choice(_col:Int, _row:Int, _text:String, callback:Void->Void):Void
        {
                var choice:Choice = {
                        col: _col,
                        row: _row,
                        button: new FlxButton(0, 0, _text, function()
                                {
                                        callback();
                                        highlight(_col, _row);
                                        hide();  // ? FIXME move to intruction
                                })
                }

                choice.button.visible = this.visible;
                m_buttons.push(choice);
                add(choice.button);
        }

        public function highlight(_col:Int, _row:Int):Void
        {
                m_col = _col;
                m_row = _row;
                if (m_mini_frame == null) {
                        m_mini_frame = new FlxSprite();
                        m_mini_frame.makeGraphic(BUTTON_WIDTH, BUTTON_HEIGHT, FlxColor.BLUE);
                        m_mini_frame.alpha = 0.5;
                        add(m_mini_frame);
                }
        }

        public function update_background():Void
        {
                var cols = 0;
                var rows = 0;

                for (choice in m_buttons) {
                        if (cols < choice.col) cols = choice.col;
                        if (rows < choice.row) rows = choice.row;
                }

                var width = (cols + 1) * BUTTON_WIDTH + cols * GAP + FRAME * 2;
                var height = (rows + 1) * BUTTON_HEIGHT + rows * GAP + FRAME * 2;

               m_background.makeGraphic(width, height, 0xFFD6D868);
        }

        public function hide():Void
        {
                visible = false;
                m_background.visible = false;
                for (choice in m_buttons) {
                        choice.button.visible = false;
                }
        }

        public function show():Void
        {
                visible = true;
                m_background.visible = true;
                for (choice in m_buttons) {
                        choice.button.visible = true;
                }
        }
}
