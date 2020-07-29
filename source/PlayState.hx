package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import haxe.io.Path;

import openfl.Assets;

import Config.Config;
import Instruction.Action;

using StringTools;

enum Speed
{
        NORMAL (i:Int);
        MAX;
}

class PlayState extends FlxState
{
        public static inline var DIM_ALPHA = 0.5;

        private var m_main_pattern:Pattern;
        private var m_instructions:Array<Instruction>;
        private var m_dim:FlxSprite;

        private var m_current_instruction = 0;

        private var m_speed_up_button:FlxButton;
        private var m_slow_down_button:FlxButton;
        private var m_speed_text:FlxText;
        private var m_speed:Speed = NORMAL (1);

        var m_started = false;
        var m_phase_cooldown = 0.0;
        var m_phase:Array<Void->Void>;
        var m_current_phase = 0;

        override public function create():Void
        {
                super.create();
                bgColor = 0xFF272B37;

                // playfield, should be locked in normal play and unlocked in edit mode
                m_main_pattern = new Pattern(Config.PLAYFIELD_WIDTH, Config.PLAYFIELD_HEIGHT);
                m_main_pattern.position = new FlxPoint(Config.FRAME, Config.FRAME);
                m_main_pattern.load_sample_lawn();
                add(m_main_pattern);

                // panel with instructions
                var COLUMNS = 5;
                var ROWS = Instruction.NUM / COLUMNS;
                var y_gap = 4;
                var y_begin = FlxG.height - (ROWS * (Instruction.HEIGHT + y_gap) + Config.FRAME) + y_gap;

                // gap between instruction columns
                var x_gap = Std.int(((FlxG.width - Config.FRAME * 2) - Instruction.WIDTH * COLUMNS) / (COLUMNS - 1));

                m_instructions = new Array();
                for (i in 0...Instruction.NUM) {

                        var x = Config.FRAME + (Instruction.WIDTH + x_gap) * (Std.int(i / ROWS));
                        var y = Std.int(y_begin + (i % ROWS) * (Instruction.HEIGHT + y_gap));

                        var instruction = new Instruction(x, y, i);
                        m_instructions.push(instruction);
                        add(instruction);
                }

                var buttons_x = Config.FRAME + Config.PLAYFIELD_WIDTH * Config.TILE_SIZE + Config.FRAME;
                var buttons_y = Config.FRAME + Config.TILE_SIZE * 10;
                var b_gap = 24;

                var run = new FlxButton(buttons_x, buttons_y + b_gap * 0, "RUN", on_run_button);
                add(run);

                var stop = new FlxButton(buttons_x, buttons_y + b_gap * 1, "STOP", on_stop_button);
                add(stop);

                var reset = new FlxButton(buttons_x, buttons_y + b_gap * 2, "CLEAR PROG", clear_program);
                add(reset);

                m_slow_down_button = new FlxButton(buttons_x, buttons_y + b_gap * 3, "SLOW DOWN", on_slown_down_button);
                add(m_slow_down_button);

                m_speed_up_button = new FlxButton(buttons_x + m_slow_down_button.width, buttons_y + b_gap * 3, "SPEED UP", on_speed_up_button);
                add(m_speed_up_button);

                m_speed_text = new FlxText(m_speed_up_button.x + m_speed_up_button.width, buttons_y + b_gap * 3 + 2, "SPEED 1");
                add(m_speed_text);

                // create_choices should be execute after creation of all instructions and buttons,
                // so choices will be on top of every instruction (prevent sprite overlapping)
                for (instruction in m_instructions) {
                        var true_choices = instruction.create_true_choices();
                        var false_choices = instruction.create_false_choices();
                        add(true_choices);
                        add(false_choices);

                        true_choices.center_on_screen();
                        false_choices.center_on_screen();
                }

                var level_box = new ScrollBox(8);
                level_box.position = new FlxPoint(buttons_x, Config.FRAME);

                var files = openfl.Assets.list();
                var level_files = new Array<String>();
                for (file in files) {
                    if (file.endsWith(".json")) level_files.push(file);
                }

                level_files.sort(function(a, b) {if (a < b) return -1; return 1;});

                var content = Assets.getText("assets/data/levels.json");
                var layers:{layers:Array<Dynamic>} = haxe.Json.parse(content);

                for (layer in layers.layers) {
                        level_box.add_entry(layer.name, function()
                                {
                                        Reg.level = layer;
                                        load_level(Reg.level);
                                        clear_program();
                                });
                }

                level_box.select(0);
                add(level_box);

                m_dim = new FlxSprite();
                m_dim.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
                m_dim.alpha = DIM_ALPHA;
                m_dim.visible = false;
                add(m_dim);

                m_phase = new Array<Void->Void>();
                m_phase.push(phase_1_goto_instruction);
                m_phase.push(phase_2_instruction);
                m_phase.push(phase_3_action);
        }

        override public function update(_elapsed:Float):Void
        {
                super.update(_elapsed);

#if desktop
                if (FlxG.keys.justPressed.Q) {
                        Sys.exit(0);
                }
#end

                var in_choice = false;
                for (instruction in m_instructions) {
                        if (instruction.in_choice) {
                                in_choice = true;
                                break;
                        }
                }

                var edit_mode = in_choice == false && m_started == false;

                // prevent editing small patterns and actions
                for (instruction in m_instructions) {
                        instruction.edit_mode = edit_mode;
                }

                // TODO editing main pattern, but not in campaign
                // m_main_pattern.edit_mode = edit_mode;

                if (m_started || m_current_phase != 0) {
                        logic(_elapsed);
                }

                // dim screen when choices panel shows up
                if (in_choice) {
                        m_dim.visible = true;
                        m_dim.alpha = Math.min(DIM_ALPHA, m_dim.alpha + 0.1);
                } else {
                        m_dim.visible = false;
                        m_dim.alpha = 0;
                }
       }

        function load_level(_level:Dynamic):Void
        {
                var data = _level.data;
                var width = _level.width;
                var height = _level.height;

                m_main_pattern.load_lawn(width, height, data);
        }

        function logic(_elapsed:Float):Void
        {
                switch (m_speed) {
                case MAX:
                        run_continous();
                        m_phase_cooldown = 0;

                case NORMAL (i):
                                //run_normal(i);

                        m_phase_cooldown -= _elapsed;
                        if (m_phase_cooldown <= 0) {
                                m_phase_cooldown += (Config.PHASE_SPEED / i) / 1000.0;

                                m_phase[m_current_phase]();
                                m_current_phase += 1;
                                m_current_phase %= m_phase.length;
                        }
                }
        }

        function run_continous():Void
        {
                // for each instruction do each phase, sth like step 20
                var cycles = m_instructions.length;

                for(i in 0...cycles) {
                        for (phase in m_phase) {
                                phase();
                        }
                }
        }

        function run_normal(speed:Int):Void
        {
                for (phase in m_phase) {
                        phase();
                }
        }

        function on_run_button():Void
        {
                load_level(Reg.level);
                m_started = true;  // FIXME get rid of this flag
                m_current_instruction = 0;
        }

        function on_stop_button():Void
        {
                m_started = false;
        }

        function on_slown_down_button():Void
        {
                switch (m_speed) {
                case NORMAL (i):
                        switch (i) {
                        case 2: m_speed = NORMAL (1);
                        case 4: m_speed = NORMAL (2);
                        case 8: m_speed = NORMAL (4);
                        case 16: m_speed = NORMAL (8);
                        }
                case MAX: m_speed = NORMAL (16);
                }

                switch (m_speed) {
                case NORMAL (i): m_speed_text.text = "SPEED " + i;
                case MAX: m_speed_text.text = "SPEED MAX";
                }
        }

        function on_speed_up_button():Void
        {
                switch (m_speed) {
                case NORMAL (i):
                        switch (i) {
                        case 1: m_speed = NORMAL (2);
                        case 2: m_speed = NORMAL (4);
                        case 4: m_speed = NORMAL (8);
                        case 8: m_speed = NORMAL (16);
                        case 16: m_speed = MAX;
                        }
                case MAX: m_speed = MAX;
                }

                switch (m_speed) {
                case NORMAL (i): m_speed_text.text = "SPEED " + i;
                case MAX: m_speed_text.text = "SPEED MAX";
                }
        }

        function clear_program():Void
        {
                m_started = false;
                for (instruction in m_instructions) {
                        instruction.reset();
                }
        }

        function execute(action:Action):Void
        {
                switch (action) {
                case PASS:
                        m_main_pattern.mover_action(PASS);
                case GO:
                        m_main_pattern.mover_action(GO);
                case TURN_LEFT:
                        m_main_pattern.mover_action(TURN_LEFT);
                case TURN_RIGHT:
                        m_main_pattern.mover_action(TURN_RIGHT);
                case CUT:
                        m_main_pattern.mover_action(CUT);
                case JUMP(i):
                        m_current_instruction = i;
                }
        }

        /**
         * Phase 1: Highlight current instruction. Move Arrow. Maybe blink.
         */
        function phase_1_goto_instruction():Void
        {
                // TODO check main conditions, ex: lawnmover crash on wall
                // TODO 1. highlight current instruction

                // TODO if debug
                //trace("----- step -----");
                //trace("current instruction = " + m_current_instruction);
                // TODO pointer arrow
        }

        /**
         * Phase 2: Match instruction.condition to main mattern
         */
        function phase_2_instruction():Void
        {
                var instruction = m_instructions[m_current_instruction];
                instruction.highlight = true;
                // 2. Check current instruction

                var pattern = instruction.pattern;

                var main_mover_area = m_main_pattern.mover_area();
                var instr_mover_area = pattern.mover_area();

                var match = Pattern.match(main_mover_area, instr_mover_area);

                // 3. If match then action (ride, turn)

                var action:Action = PASS;

                switch (match) {
                case MATCH:
                        instruction.highlight_good();
                        action = instruction.action_true;
                case DISMATCH:
                        instruction.highlight_bad();
                        action = instruction.action_false;
                }

                m_current_instruction += 1;
                m_current_instruction %= m_instructions.length;

                // execute should be called after m_current_instruction because
                // it modifies it (JUMP_XX)
                execute(action);
        }

        /**
         * Phase 3: Cleanup all blinks and flashes.
         */
        function phase_3_action():Void
        {
                for (instr in m_instructions) {
                        instr.highlight = false;
                }
        }
}
