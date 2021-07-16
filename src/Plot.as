package 
{
	/* Класс Plot представляет единичная ячейка сетки */
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Endian;

	public class Plot extends Sprite
	{
		private var _state:int;              // состояние ячейки
		public const PLOT_SIZE:uint = 15;    // размер ячейки
		private var _row:uint;				 // номер ряда
		private var _col:uint;				 // номер столбца
		private var _name:String;
		private var _indexFar:uint;          // индекс приближённости к финишу
		private var _indexCost:uint;         // стоимость перехода
		private var _totalCost:uint;         // общая стоимость перехода
		private var _textField:TextField;
		private var _alreadyUse:Boolean;     // уже использован как часть пути
		private var _alreadyInArray:Boolean; // уже в общем массиве
		private var _spliceCandidate:Boolean;// кандидат на зачистку
		private var _adjacent:Array;         // массив с соседями
		private var _whoIsPushMe:Plot;       // тот, кто добавил меня в AllAdjucent массив
		
		//CONSTRUCTOR//
		public function Plot(state:int)
		{
			_state = state;
			addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event):void
		{
			draw(_state);
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		// draw......................................................
		public function draw(state:int):void
		{
			switch (state)
			{
				case -1: // непроходимый
					graphics.beginFill(0x666666, 1);
					graphics.drawRoundRect(0, 0, PLOT_SIZE, PLOT_SIZE, 5, 5);
					graphics.endFill();
					break;
				case 0: // пустой
					graphics.beginFill(0xFFFFFF, 1);
					graphics.drawRect(0, 0, PLOT_SIZE, PLOT_SIZE);
					graphics.endFill();
					graphics.lineStyle(1, 0x000000, 0.2);
					graphics.moveTo(1, 1);
					graphics.lineTo(13, 1);
					graphics.lineTo(13, 13);
					graphics.lineTo(1, 13);
					graphics.lineTo(1, 2);
					graphics.endFill();
					break;
				case 1: // путь
					graphics.beginFill(0x009933, 1);
					graphics.drawRoundRect(0, 0, PLOT_SIZE, PLOT_SIZE, 5, 5);
					graphics.endFill();
					break;
				case 2: // сосед
					graphics.beginFill(0xCCCCFF, 1);
					graphics.drawRoundRect(0, 0, PLOT_SIZE, PLOT_SIZE, 5, 5);
					graphics.endFill();
					break;
				case 3: // старт
					graphics.beginFill(0xFF0000, 1);
					graphics.drawCircle(7, 7, 5);
					graphics.endFill();
					break;
				case 4: // финиш
					graphics.beginFill(0x0000FF, 1);
					graphics.drawCircle(7, 7, 5);
					graphics.endFill();
					break;
				case 5: // кандидат
					graphics.beginFill(0x00FF00, 1);
					graphics.drawRoundRect(0, 0, PLOT_SIZE, PLOT_SIZE, 5, 5);
					graphics.endFill();
					break;
				case 6: // удаленный из пути
					graphics.beginFill(0x999999, 1);
					graphics.drawRoundRect(3, 3	, 8, 8, 5, 5);
					graphics.endFill();
					break;
				case 7: // обратный путь (кандидат)
					graphics.beginFill(0xFFCC00, 1);
					graphics.drawRoundRect(0, 0, PLOT_SIZE, PLOT_SIZE, 5, 5);
					graphics.endFill();
					break;
				case 8: // обратный путь 
					graphics.beginFill(0xFFFF99, 1);
					graphics.drawRoundRect(0, 0, PLOT_SIZE, PLOT_SIZE, 5, 5);
					graphics.endFill();
					break;
				case 9: // истинный путь
					graphics.beginFill(0xFF3300, 1);
					graphics.drawRoundRect(0, 0, PLOT_SIZE, PLOT_SIZE, 5, 5);
					graphics.endFill();
					break;
			}
		}
		
		// add text............................................
		public function addText(text:*):void
		{
			// если текстовое поле уже существует
			if(textField != null)
			{
				removeChild(textField);
				textField = null;
			}
			textField = new TextField();
			var format:TextFormat = new TextFormat("Arial", 8);
			textField.selectable = false;
			textField.width = textField.height = 15;
			textField.text = String(text);
			textField.setTextFormat(format);
			addChild(textField);
		}
		
		// calculate indexFar.............................................
		// просчёт индекса приближённости к финишу
		public function calculateIndexFar(start:Plot, finish:Plot):uint
		{
			_indexFar = Math.abs(finish.row-start.row)+Math.abs(finish.col-start.col)+20;
			return _indexFar;
		}
		
		// getters & setters...........................................
		public function get indexFar():uint
		{
			return _indexFar;
		}
		
		public function set indexFar(value:uint):void
		{
			_indexFar = value;
		}
		
		public function get state():int
		{
			return _state;
		}
		
		public function set state(value:int):void
		{
			_state = value;
			graphics.clear();	
			draw(_state);
		}

		public function get col():uint
		{
			return _col;
		}
		
		public function set col(value:uint):void
		{
			_col = value;
		}
		
		public function get row():uint
		{
			return _row;
		}
		
		public function set row(value:uint):void
		{
			_row = value;
		}
		
		public override function get name():String
		{
			return _name;
		}
		
		public override function set name(value:String):void
		{
			_name = value;
		}
		
		
		public function get alreadyUse():Boolean
		{
			return _alreadyUse;
		}
		
		public function set alreadyUse(value:Boolean):void
		{
			_alreadyUse = value;
		}

		public function get alreadyInArray():Boolean
		{
			return _alreadyInArray;
		}

		public function set alreadyInArray(value:Boolean):void
		{
			_alreadyInArray = value;
		}

		public function get indexCost():uint
		{
			return _indexCost;
		}

		public function set indexCost(value:uint):void
		{
			_indexCost = value;
		}

		public function get totalCost():uint
		{
			_totalCost = (_indexFar*5 + _indexCost);
			return _totalCost;
		}

		public function set totalCost(value:uint):void
		{
			_totalCost = value;
		}

		public function get adjacent():Array
		{
			return _adjacent;
		}

		public function set adjacent(value:Array):void
		{
			_adjacent = value;
		}

		public function get textField():TextField
		{
			return _textField;
		}

		public function set textField(value:TextField):void
		{
			_textField = value;
		}

		public function get spliceCandidate():Boolean
		{
			return _spliceCandidate;
		}

		public function set spliceCandidate(value:Boolean):void
		{
			_spliceCandidate = value;
		}

		public function get whoIsPushMe():Plot
		{
			return _whoIsPushMe;
		}

		public function set whoIsPushMe(value:Plot):void
		{
			_whoIsPushMe = value;
		}


	}
}