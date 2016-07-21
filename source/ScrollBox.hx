package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;

import Config.Config;

typedef Entry = {
        var label:FlxText;
        var callback:Void->Void;
}

class ScrollBox extends FlxGroup
{
        public static inline var ENTRY_HEIGHT = 14;  // label text height
        private var m_width:Int;
        private var m_height:Int;
        private var m_selected:Int;
        private var m_background:FlxSprite;
        private var m_mini_frame:FlxSprite;
        private var m_visible_entries:Int;
        private var m_top_entry:Int;
        private var m_entries:Array<Entry>;
        private var m_previous:FlxButton;
        private var m_next:FlxButton;

        public var position(default, set):FlxPoint;


        public function new(_visible_entries:Int):Void
        {
                super();
                m_visible_entries = _visible_entries;
                m_top_entry = 0;

                m_width = Config.BUTTON_WIDTH * 2;
                m_height = _visible_entries * ENTRY_HEIGHT;

                m_background = new FlxSprite();
                m_background.makeGraphic(m_width, m_height, FlxColor.GRAY);  // 160 = 2 * 80
                add(m_background);

                m_mini_frame = new FlxSprite();
                m_mini_frame.makeGraphic(m_width, ENTRY_HEIGHT, 0xFF9B5392);
                add(m_mini_frame);

                m_entries = new Array<Entry>();

                m_previous = new FlxButton(0, 0, "PAGE UP", function ()
                                {
                                        scroll(-m_visible_entries);
                                });

                m_next = new FlxButton(0, 0, "PAGE DOWN", function ()
                                {
                                        scroll(m_visible_entries);
                                });

                add(m_previous);
                add(m_next);

                position = new FlxPoint(0, 0);
        }

        public function set_position(_position:FlxPoint):FlxPoint
        {
                this.position = _position;
                recalc_positions();
                return this.position;
        }

        override public function update(_elapsed:Float):Void
        {
                super.update(_elapsed);

                if (FlxG.mouse.justPressed && mouseover()) {
                        var my = FlxG.mouse.y;
                        var mouse_entry = Std.int((my - this.position.y) / ENTRY_HEIGHT);
                        var entry = m_top_entry + mouse_entry;
                        select(entry);
                }

                if (FlxG.mouse.wheel != 0 && mouseover()) {
                            scroll(-FlxG.mouse.wheel);
                }
        }

        function scroll(_pos:Int):Void
        {
                m_top_entry += _pos;

                if (m_top_entry > m_entries.length - m_visible_entries) {
                        m_top_entry = m_entries.length - m_visible_entries;
                }
                if (m_top_entry < 0) m_top_entry = 0;

                recalc_positions();
        }

        function mouseover():Bool
        {
                var x = this.position.x;
                var y = this.position.y;
                var mx = FlxG.mouse.x;
                var my = FlxG.mouse.y;

                var mx_in = x < mx && mx < x + m_width;
                var my_in = y < my && my < y + m_height;

                return mx_in && my_in;
        }

        public function select(_entry:Int):Void
        {
                if (_entry < 0 || _entry >= m_entries.length) return;

                m_selected = _entry;
                m_entries[m_selected].callback();
                recalc_positions();
        }

        function recalc_positions():Void
        {
                var x = this.position.x;
                var y = this.position.y;

                m_background.x = x;
                m_background.y = y;

                for (i in 0...m_entries.length) {
                        var entry = m_entries[i];
                        var label = entry.label;

                        if (i < m_top_entry || i >= m_top_entry + m_visible_entries) {
                                label.visible = false;
                        } else {
                                label.visible = true;
                        }

                        label.x = x;
                        label.y = y + (i - m_top_entry) * ENTRY_HEIGHT;
                }

                var selected_visible = m_top_entry <= m_selected && m_selected < m_top_entry + m_visible_entries;

                if (selected_visible) {
                        m_mini_frame.visible = true;
                        m_mini_frame.x = this.position.x;
                        m_mini_frame.y = this.position.y + ENTRY_HEIGHT * (m_selected - m_top_entry);
                } else {
                        m_mini_frame.visible = false;
                }

                m_previous.x = x;
                m_next.x = x + 80;

                m_previous.y = y + m_background.height;
                m_next.y = y + m_background.height;
        }

        public function add_entry(_name:String, _callback:Void->Void):Void
        {
                var entry:Entry = { label: new FlxText(), callback: _callback };
                entry.label.text = _name;
                add(entry.label);
                m_entries.push(entry);
        }
}
