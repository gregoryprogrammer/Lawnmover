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
import Tile.TileType;

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
        private var m_arrow:FlxSprite;

        private var m_current_instruction = 0;

        private var m_speed_button:FlxButton;
        private var m_speed:Speed = NORMAL (4);

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

                m_dim = new FlxSprite();
                m_dim.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
                m_dim.alpha = DIM_ALPHA;
                m_dim.visible = false;

                // panel with instructions
                var COLUMNS = 5;
                var ROWS = Instruction.NUM / COLUMNS;
                var y_gap = 4;
                var y_begin = FlxG.height - (ROWS * (Instruction.HEIGHT + y_gap) + Config.FRAME) + y_gap;

                // gap between instruction columns
                var x_gap = Std.int(((FlxG.width - Config.FRAME * 2) - Instruction.WIDTH * COLUMNS) / (COLUMNS - 1));

                m_arrow = new FlxSprite();
                m_arrow.makeGraphic(Instruction.WIDTH + 8, Instruction.HEIGHT + 8, FlxColor.WHITE);
                m_arrow.visible = true;
                add(m_arrow);

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

                var run = new FlxButton(buttons_x, buttons_y + b_gap * 0, "START", on_run_button);
                add(run);

                var stop = new FlxButton(buttons_x, buttons_y + b_gap * 1, "STOP", on_stop_button);
                add(stop);

                var reset = new FlxButton(buttons_x, buttons_y + b_gap * 2, "SKASUJ", clear_program);
                add(reset);

                m_speed_button = new FlxButton(buttons_x, buttons_y + b_gap * 3, "PREDKOSC 4", on_speed_button);
                add(m_speed_button);

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
                        Reg.saved_program[layer.name] = new Array<Action>();
                        level_box.add_entry(layer.name, function()
                                {
                                        Reg.level = layer;
                                        clear_program();
                                        load_level(Reg.level);
                                });
                }

                level_box.select(0);
                add(level_box);

                add(m_dim);

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

                m_phase = new Array<Void->Void>();
                m_phase.push(phase_1_goto_instruction);
                m_phase.push(phase_2_instruction);
                m_phase.push(phase_3_action);

                move_arrow();
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

                // saving program
                for (i in 0...m_instructions.length) {
                    var action_true = m_instructions[i].action_true;
                    var action_false = m_instructions[i].action_false;

                    var idx_true = 2 * i;
                    var idx_false = 2 * i + 1;
                    var program_arr = Reg.saved_program[Reg.level.name];
                    program_arr[idx_true] = action_true;
                    program_arr[idx_false] = action_false;

                    var pattern_tiles = m_instructions[i].pattern.get_tiles();
                    for (t in 0...pattern_tiles.length) {
                        var tile = pattern_tiles[t];
                        var tile_key = "" + Reg.level.name + "_" + i + "_" + t;
                        Reg.saved_pattern[tile_key] = tile.type;
                    }
                }
        }

        function move_arrow():Void
        {
                var instruction = m_instructions[m_current_instruction];
                m_arrow.x = instruction.x - 4;
                m_arrow.y = instruction.y - 4;
        }

        function load_level(_level:Dynamic):Void
        {
                var data = _level.data;
                var width = _level.width;
                var height = _level.height;

                m_main_pattern.load_lawn(width, height, data);

                // TODO load program for this level

                var program = Reg.saved_program[_level.name];

                for (i in 0...m_instructions.length) {
                    var idx_true = 2 * i;
                    var idx_false = 2 * i + 1;
                    var action_true = program[idx_true];
                    var action_false = program[idx_false];

                    if (action_true != null) m_instructions[i].action_true = action_true;
                    if (action_false != null) m_instructions[i].action_false = action_false;

                    var pattern_tiles = m_instructions[i].pattern.get_tiles();
                    for (t in 0...9) {
                        var tile_key = "" + Reg.level.name + "_" + i + "_" + t;
                        var tile_type = Reg.saved_pattern[tile_key];
                        if (tile_type != null) {
                            pattern_tiles[t].type = tile_type;
                        }
                    }
                    m_instructions[i].pattern.set_tiles(pattern_tiles);
                }
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
                m_current_instruction = 0;
                m_started = false;
                move_arrow();
        }

        function on_speed_button():Void
        {
                switch (m_speed) {
                case NORMAL (i):
                        switch (i) {
                        case 1: m_speed = NORMAL (2);
                        case 2: m_speed = NORMAL (4);
                        case 4: m_speed = NORMAL (8);
                        case 8: m_speed = MAX;
                        }
                case MAX: m_speed = NORMAL (1);
                }

                switch (m_speed) {
                case NORMAL (i): m_speed_button.label.text = "PREDKOSC " + i;
                case MAX: m_speed_button.label.text = "PREDKOSC MAX";
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
                move_arrow();
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
