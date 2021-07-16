package 
{
	/* Класс Grid представляет сетку */
	
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	public class PathGrid extends Sprite
	{
		private var txt_Console:TextField;    // консоль
		private var mc_trigger:Mc_trigger;	  // переключатель режима поиска
		private var btn_nextStep:Btn_nextStep;// шаг поиска
		
		private var _amountRows:uint;    	  // количество рядов
		private var _amountCols:uint;	 	  // количество стобцов
		private var _amountWalls:uint;	 	  // количество стен
		
		private var gridArray:Array;	 	  // двумерный массив со всеми элементами
		private var gridArrayMono:Array;      // одномерный массив со всеми элементами
		private var path:Array;   		      // путь 
		private var tempPath:Array;		      // временный путь (вспомогательный)
		private var allAdjucent:Array;        // общий массив для всех соседей	
		
		private var _stage:Stage;
		private var _start:Plot;
		private var _finish:Plot;
		private var clickCounter:uint;
		private var stepByStep:Boolean;       // переключение между пошаговым поиском и одношаговым
		private var reversePath:Boolean;
		private var format:TextFormat;
		private var tempStart:Plot;
		
		
		// CONSTRUCTOR //
		
		public function PathGrid(stage:Stage, rows:uint, cols:uint, walls:uint)
		{	
			clickCounter = 0;
			_amountRows = rows;
			_amountCols = cols;
			_amountWalls = walls;
			_stage = stage;
			stepByStep = true;
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		// INIT...............................................................
		private function init(e:Event):void
		{
			buildGrid();
			placeWalls();
			allAdjucent = new Array();
			
			tempPath = new Array(); 
			_stage.addEventListener(MouseEvent.CLICK, clickListener);
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, moveListener);
			
			// переключатель режимов поиска
			// mc_trigger
			mc_trigger = new Mc_trigger();
			mc_trigger.x = 163;
			mc_trigger.y = 353;
			_stage.addChild(mc_trigger);
			mc_trigger.stop();
			mc_trigger.addEventListener(MouseEvent.CLICK, pushTheTrigger);
			
			// консоль
			// txt_Console
			txt_Console = new TextField();
			var font:Trebuchet = new Trebuchet();
			format = new TextFormat(font.fontName, 15, 0x66FF66);
			format.bold = true;
			txt_Console.x = 214;
			txt_Console.y = 328;
			txt_Console.width = 280;
			txt_Console.height = 60;
			txt_Console.selectable = false;
			txt_Console.multiline = true;
			txt_Console.wordWrap = true;
			_stage.addChild(txt_Console);
			console("Choose start and final position");
			//
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		// CONSOLE...............................................................
		private function console(text:String):void
		{
			txt_Console.text = text;
			txt_Console.setTextFormat(format);
		}
		
		// MOVE LISTENER..........................................................
		protected function moveListener(event:MouseEvent):void
		{
			// отображает имя ячейки в консоли
			if(event.target is Plot)
			{
				console(event.target.name);
			}
			// в случае, если ячейки с текстовыми полями
			else if(event.target is TextField)
			{
				if(event.target != txt_Console)
				{
					console(event.target.parent.name);
				}	
			}
		}
		
		// PUSH THE TRIGGER..........................................................
		// смена поискового режима
		protected function pushTheTrigger(event:MouseEvent):void
		{
			if(mc_trigger.currentFrame == 1)
			{
				mc_trigger.gotoAndStop(2);
			}
			else
			{
				mc_trigger.gotoAndStop(1);
			}
			stepByStep = !stepByStep;
		}
		
		// BUILD GRID...............................................................
		// построение сетки
		private function buildGrid():void
		{
			gridArray = new Array();
			gridArrayMono = new Array();
			
			for (var i:uint = 0; i < _amountRows; i++) 
			{
				gridArray[i] = new Array();
				
				for (var j:int = 0; j < _amountCols; j++) 
				{
					var plot:Plot = new Plot(0);
					gridArray[i][j] = plot;
					gridArrayMono.push(plot);
					plot.x = i*plot.PLOT_SIZE;
					plot.y = j*plot.PLOT_SIZE;
					plot.row = j+1;
					plot.col = i+1;
					plot.name = String(plot.row +"_"+ plot.col);
					_stage.addChild(plot);
				}
			}
		}
		
		// PLACE WALLS...............................................................
		// расстановка препятствий
		private function placeWalls():void
		{
			for (var i:uint = 0; i < _amountWalls; i++) 
			{
				var randomIndex:uint = Math.round((Math.random()*gridArrayMono.length-1))
				var randomPlot:Plot = gridArrayMono[randomIndex];
				if(randomPlot != null)
				{
					randomPlot.state = -1;
				}
			}
			
			// все элементы, у которых соседей меньше двух, делаем непроходимыми
			for (var j:int = 0; j < gridArrayMono.length; j++) 
			{
				var wallCandidate:Plot = gridArrayMono[j];
				wallCandidate.adjacent = searchAdjacent(wallCandidate);
				if(wallCandidate.adjacent.length < 2)
				{
					wallCandidate.state = -1;
				}
			}
		}
		
		// INDEX ALL...............................................................
		// индексирование и поиск соседей для всех
		private function indexAll():void
		{
			for (var i:uint = 0; i < gridArrayMono.length; i++) 
			{
				var plot:Plot = gridArrayMono[i];
				plot.indexFar = plot.calculateIndexFar(plot, _finish);
				plot.adjacent = searchAdjacent(plot);
				// выключить комментарий, если нужно отобразить значения
				//plot.addText(plot.totalCost);
			}
		}
		
		// CLICK LISTENER...........................................................
		protected function clickListener(event:MouseEvent):void
		{	
			if(event.target is Plot)
			{
				if(clickCounter < 2 && event.target.state != -1)
				{
					if (_start == null)
					{
						_start = event.target as Plot;
						// сохраняем значение стартовой позиции 
						// (пригодится на обратном пути)
						tempStart = _start;
						_start.draw(3);
						clickCounter++;
					}
					else if (_finish == null)
					{
						if(event.target != _start)
						{
							_finish = event.target as Plot;
							_finish.draw(4);
							indexAll();
							clickCounter++;
							console("Let's find shortest path");
							// add btn_nextStep
							if(btn_nextStep == null)
							{
								btn_nextStep = new Btn_nextStep();
								btn_nextStep.x = 350;
								btn_nextStep.y = 50;
								btn_nextStep.gotoAndStop(1);
								_stage.addChild(btn_nextStep);
								btn_nextStep.addEventListener(MouseEvent.CLICK, pushTheButton);
							}
						}
					}
				}
			}
		}
		
		// PUSH THE BUTTON...........................................................
		protected function pushTheButton(event:MouseEvent):void
		{
			// 1 кадр кнопки - "ПОИСК"
			if(btn_nextStep.currentFrame == 1)
			{
				// если пошаговый режим поиска
				
				if(stepByStep)
				{
					if(_start != null && _finish != null)
					{
						searchStep(_start, _finish);
					}
				}
				// одношаговый режим поиска
				else
				{
					while(_start != _finish)
					{
						if(_start != null && _finish != null)
						{
							searchStep(_start, _finish);
						}
					}
				}
			}
			// 2-й кадр кнопки - "НОВЫЙ ПОИСК"
			else 
			{
				console("Choose start and final position");
				reset();
			}
		}
		
		// RESET...............................................................
		// сброс всего
		private function reset():void
		{
			// обнуляем значения
			_start = null;
			_finish = null;
			reversePath = false;
			btn_nextStep.gotoAndStop(1);
			clickCounter = 0;
			buildGrid();
			placeWalls();
			
			allAdjucent = new Array();
			tempPath = new Array(); 
		}
		
		// SEARCH STEP..............................................
		// шаг поиска
		public function searchStep(start:Plot, finish:Plot):void
		{
				var candidate:Plot;       // кандидат
				var prevCandidate:Plot;   // предыдущий кандидат
				var current:Plot = start; // текущий элемент пути
				var prev:Plot;            // предыдущий элемент пути 
				
				
				tempPath.push(current);

				current.spliceCandidate = false;
				current.alreadyUse = true;
				// ищем лучшего кандидата
				// сначала в соседях текущего
				candidate = bestCandidate(current.adjacent);
				
				/* понижаем приоритет текущего на время, пока он текущий
				(В некоторых случаях предотвращает зацикленность, когда 
				например лучший кандидат всё время лучший из лучших, но он является
				тупиковым )
				в конце шага возвращаем значение */
				current.indexCost += 3;
				
				// добавляем всех соседей в общий массив для вообще всех соседей
				for (var b:uint = 0; b < current.adjacent.length; b++) 
				{
					var curAdj:Plot = current.adjacent[b];
					if(curAdj.alreadyInArray == false && curAdj.alreadyUse == false)
					{
						allAdjucent.push(curAdj);
						// каждого соседа можно добавить в массив единожды
						// о чём и говорит метка alreadyInArray
						curAdj.alreadyInArray = true;
					}
					// рисуем соседей
					if(reversePath == false)
					{
						curAdj.draw(2);
					}
					// отмечаем того, кто добавил соседа в массив.
					// Когда поиск перескакивает на другое направление - 
					// bestCandidate(allAdjucent)
					// все лишние ответвления (целый диапазон массива)
					// усекаются, отмечаются как кандидаты на удаление
					// из массива (свойство splicedCandidate). Вот тут то
					// и пригодится индекс этого элемента (элемента, который
					// добавил лучшего кандидата) и текущего
					// чтобы задать диапазон отсечения от массива.
					curAdj.whoIsPushMe = current;
				}
				// отображаем текущую стоимость перехода
				//current.addText(current.totalCost);
				
				// если не находим, у соседей текущего, ищем в общем массиве
				if(candidate == null)
				{
					candidate = bestCandidate(allAdjucent);
					// отмечаем лишние элементы для уборки (если есть таковые)
					tempPath = markedSpliced(tempPath, candidate, current);
					// делаем текущий элемент, тем, который добавил кандидата в список
					candidate.whoIsPushMe = current;
				}
				// кандидат найден
				else
				{
					// если кандидат не использовался в качестве пути
					if(candidate.alreadyUse == false)
					{
						// КАНДИДАТ ДЕШЕВЛЕ ТЕКУЩЕГО
						if(candidate.totalCost < current.totalCost)
						{
							trace("cand.total < cur.total");
						}
						// КАНДИДАТ ДОРОЖЕ ТЕКУЩЕГО ИЛИ РАВЕН ЕМУ
						else if (candidate.totalCost >= current.totalCost)
						{
							trace("cand.total >= curr.total");
							
							// В этом случае сверим только индексы отдалённости
							// КАНДИДАТ БЛИЖЕ ТЕКУЩЕГО
							if(candidate.indexFar <= current.indexFar)
							{
								trace("cand.Far <= cur.Far");
							}
							// КАНДИДАТ ДАЛЬШЕ ТЕКУЩЕГО
							else if (candidate.indexFar > current.indexFar)
							{
								trace("cand.Far > cur.Far");
								// тогда ищем лучшего кандидата из общего массива
								candidate = bestCandidate(allAdjucent);
								tempPath = markedSpliced(tempPath, candidate, current);
								candidate.whoIsPushMe = current;
							}
						}
					}
					// если кандидат использовался уже в пути,
					// ищем другого соседа - получше
					else 
					{
						trace("cand.alreadyUse == true");
						candidate = bestCandidate(allAdjucent);
						tempPath = markedSpliced(tempPath, candidate, current);
						candidate.whoIsPushMe = current;
					}
					
					if(candidate != null)
					{
						if(reversePath == false)
						{
							// отрисовываем путь
							for (var h:uint; h < tempPath.length; h++) 
							{
								var o:Plot = tempPath[h];
								o.draw(1);
							}
							// рисуем кандидата
							candidate.draw(5);
							// отрисовываем текущий
							current.draw(3);
						}
						else if(reversePath)
						{
							// рисуем кандидата
							candidate.draw(7);
							// отрисовываем текущий
							current.draw(8);
						}
					}
					if(prevCandidate != null)
					{
						trace("PREV CANDIDATE : "+ prevCandidate.name);
					}
					
					if(candidate == null)
					{	
						console("Sorry, no ways. PLease refresh grid.");
						reset();
					}
					// если предыдущий элемент является текущим, значит
					// это ситуация, когда тот же самый элемент ищет другого соседа
					// значит прошлый кандидат-сосед не подходит и его можно отметить для уборки
					if(prev == current)
					{
						prevCandidate.spliceCandidate = true;
					}
					
					// кандидат становится предыдущим кандидатом
					prevCandidate = candidate;
					// текущий элемент становится предыдущим
					prev = current;
					
					// возвращаем иходное значение
					current.indexCost -= 3;
					// меняем стартовую позицию на позицию кандидата
					_start = candidate;
					
					// если финиш достигнут - начинаем поиск в обратном направлении
					if(_start == _finish && reversePath == false)
					{
						tempPath.push(_start);
						// удаляем элементы ранее отмеченные для уборки
						tempPath = cleanerPath(tempPath);
						// дополнительная уборка лишних элементов
						tempPath = removeWastePlots(tempPath);
						
						path = tempPath;
						reversePath = true;
						
						
						for (var k:int = 0; k < allAdjucent.length; k++) 
						{
							var g:Plot = allAdjucent[k];
							g.alreadyInArray = false;
							g.alreadyUse = false;
						}
						_start = _finish;
						
						_finish = tempStart;
						_finish.alreadyUse = false;
						_start.alreadyUse = true;
						
						allAdjucent = new Array();
						tempPath = new Array();
						indexAll();
					}
					// если финиш достигнут уже на обратном пути
					else if (_start == _finish && reversePath)
					{
						tempPath.push(_finish);
						// удаляем элементы ранее отмеченные для уборки
						tempPath = cleanerPath(tempPath);
						// дополнительная уборка лишних элементов
						tempPath = removeWastePlots(tempPath);
						
						
						// если новый путь короче первого
						// заменяем его новым вариантом
						if(tempPath.length < path.length)
						{
							path = tempPath;
						}
						
						// рисуем путь
						for (var i:uint = 0; i < path.length; i++) 
						{
							var truePlot:Plot = path[i];
							truePlot.draw(9);
						}
								
						console("Path finded !"+"\n"+"lenght of path is : "
							+ path.length + " steps");
						btn_nextStep.gotoAndStop(2);
					}	
				}
				if(prev != null)
				{
					console("prev : " + prev.name + ", current : " + current.name
						+ ", cand : " + candidate.name 
						+ ", path : " + tempPath.length);
				}
				else
				{
					console("current : " + current.name
						+ ", cand : " + candidate.name 
						+ ", path : " + tempPath.length);
				}
		}
		
		// MARKED SPLICED......................................................
		// отмечаем кандидатов для уборки
		private function markedSpliced(markedPath:Array, cand:Plot, cur:Plot):Array
		{
			var _markedPath:Array = markedPath;
			var splicedIndex_1:uint = _markedPath.indexOf(cand.whoIsPushMe);
			var splicedIndex_2:uint = _markedPath.indexOf(cur);
			var sliced:Array = _markedPath.slice(splicedIndex_1+1, splicedIndex_2+1);
			
			
			for (var j:uint = 0; j < sliced.length; j++) 
			{
				var currentSpliced:Plot = sliced[j];
				currentSpliced.spliceCandidate = true;
			}
			return _markedPath;
		}
		
		// CLEANER PATH......................................................
		// очистка пути от ложных направлений 
		private function cleanerPath(pathForCleaner:Array):Array
		{
			// рисуем отмеченных для уборки
			for (var i:uint = pathForCleaner.length-1; i > 0; i--) 
			{
				var curSpliced:Plot = pathForCleaner[i];
				if(curSpliced.spliceCandidate == true)
				{
					curSpliced.draw(6);
					
					pathForCleaner.splice(i, 1);
					// если массив не работает без этого элемента
					if(workPath(tempPath) == false)
					{
						// возвращаем элемент на место
						pathForCleaner.splice(i, 0, curSpliced);
					}
				}
			}
			return pathForCleaner;
		}
		
		private function tracePath(arr:Array):String
		{
			var traceText:String = "";
			for (var j:int = 0; j < arr.length; j++) 
			{
				var cur:Plot = arr[j];
				traceText += "_["+cur.name+"]";
			}
			return traceText;
		}
		
		// REMOVE WASTE PLOTS........................................................
		// хорошо удаляет единичные ненужные ответвления
		private function removeWastePlots(pathForClaen:Array):Array
		{
			var _newPath:Array = pathForClaen;
			for (var i:uint = _newPath.length-1; i > 0; i--) 
			{
				if(i != _newPath.length-1)
				{
					var current:Plot = _newPath[i];
					// удаляем элемент из массива
					_newPath.splice(i, 1);
					// проверяем путь на разрыв
					// если в пути есть разрыв, значит возвращаем удалённый элемент на место
					if(workPath(_newPath) == false)
					{
						_newPath.splice(i, 0, current);
					}
				}
			}
			return _newPath;
		}
		
		// WORK PATH...............................................................
		// Функция проверяет путь на разрывы. 
		// Каждый элемент должен быть соседом следующему.
		private function workPath(pathForWork:Array):Boolean
		{
			var isWork:Boolean;
			var argPath:Array = pathForWork;
			var counter:uint = 0; // считает все удачные соседства
			for (var i:uint = 0; i < argPath.length; i++) 
			{
				// текущий
				var current:Plot = argPath[i];
					// следующий
					var next:Plot = argPath[i+1];
					if(next != null)
					{
						// пробегаемся по соседям следующего
						for (var j:uint = 0; j < next.adjacent.length; j++) 
						{
							var nextAdj:Plot = next.adjacent[j];
							// если текущий является соседом следующему 
							if(current == nextAdj)
							{
								counter++;
							}
						}	
					}
			}
			// если счётчик равен дленне пути-1, значит разрывов нет
			if(counter == argPath.length-1)
			{
				isWork = true;
			}
			else
			{
				isWork = false;
			}
			return isWork;
		}
		
		// BEST CANDIDATE............................................................
		// функция возвращает лучшего кандидата массива(с наименьшим totalCost)
		private function bestCandidate(array:Array):Plot
		{
			if(array.length != 0)
			{
				var best:Plot = array[0];
				for (var i:uint = 1; i < array.length; i++) 
				{
					var next:Plot = array[i];
					if(next.totalCost < best.totalCost && next.alreadyUse == false)
					{
						best = next;
					}
				}
				return best;
			}
			else
			{
				return null;
			}
		}
		
		// SEARCH ADJUCENT............................................................
		// определение соседей
		private function searchAdjacent(current:Plot):Array
		{
			var adjes:Array = new Array();
			for (var i:int = 0; i < gridArrayMono.length; i++) 
			{	
			    var adj:Plot = gridArrayMono[i];
				if (adj != null && adj != current 
					&& adj.state != -1 && adj.alreadyUse == false)
				{
					if(adj.row == current.row -1 || 
						adj.row == current.row +1 || 
						adj.row == current.row)
					{
						if(adj.col == current.col -1 || 
							adj.col == current.col || 
							adj.col == current.col +1)
						{
							adjes.push(adj);
						}
					}
				}
			}
			return adjes;
		}
	}
}