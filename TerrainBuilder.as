package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	[SWF(width="720", height="480", frameRate="24", backgroundColor="0x333333")]
	public class TerrainBuilder extends Sprite
	{
		private var canvas:BitmapData;
		private var bm:Bitmap;
		private var mDown:Boolean = false;
		private var lastX:int = -1;
		private var dirty:Boolean = true;
		private var heightMap:Vector.<int> = new Vector.<int>();
		private var blur:BlurFilter;
		private var smoother:ColorMatrixFilter;
		
		public function TerrainBuilder()
		{
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			var shape:Shape = new Shape();
			var m:Matrix = new Matrix();
			m.createGradientBox( 720, 480, 90 * Math.PI/180, 10, 10 );
			
			shape.graphics.beginGradientFill( GradientType.LINEAR, [0x406D87, 0x674E8E], [1, 1], [0, 255], m, "pad" );
			shape.graphics.drawRect( 0, 0, 720, 480 );
			shape.graphics.endFill();
			shape.cacheAsBitmap = true;
			addChild( shape );
			
			canvas = new BitmapData( 720, 480, true, 0xFFFFFFFF );
			bm = new Bitmap( canvas, "auto", true );
			bm.blendMode = BlendMode.MULTIPLY;
			bm.cacheAsBitmap = true;
			bm.alpha = .35;
			addChild( bm );
			
			blur = new BlurFilter( 10, 10, 2 );
			smoother = new ColorMatrixFilter( [11,0,0,0,-1735,0,11,0,0,-1735,0,0,11,0,-1735,0,0,0,1,0] );
			
			// set empty height map
			for ( var i:int = 0; i <= canvas.width; i++ ) { heightMap.push( canvas.height ); }
			
			stage.addEventListener( MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true );
			stage.addEventListener( MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true );
			addEventListener( Event.ENTER_FRAME, update, false, 0, false );
		}
		
		private function mouseDownHandler( event:MouseEvent ):void
		{
			mDown = true;
			dirty = true;
		}
		private function mouseUpHandler( event:MouseEvent ):void
		{
			mDown = false;
			dirty = false;
			lastX = -1;
			
			canvas.applyFilter( canvas, canvas.rect, new Point(), blur );
			canvas.applyFilter( canvas, canvas.rect, new Point(), smoother );
		}
		
		private function render():void
		{
			// render
			if ( dirty )
			{
				bm.filters = [];
				canvas.fillRect( canvas.rect, 0xFFFFFFFF );
				canvas.lock();
				for ( var __x:int = 0; __x <= canvas.width; __x++ )
				{
					// get the start pos
					var s:int = heightMap[__x];
					for ( var __y:int = canvas.height; __y >= s; __y-- )
					{
						canvas.setPixel( __x, __y, 0xFF000000 );
					}
				}
				canvas.unlock();
			}
		}
		
		public function update( event:Event ):void
		{
			// update heightMap
			if ( mDown )
			{
				// get the x mouse
				var _x:int = Math.round( stage.mouseX );
				var _y:int = Math.round( stage.mouseY );
				if ( _x > canvas.width )  { _x = canvas.width; }
				if ( _x < 0 ) { _x = 0; }
				if ( _y > canvas.height ) { _y = canvas.height; }
				if ( _y < 0 ) { _y = 0; }
				
				// interpolation = a + percent * ( b - a )
				
				if ( lastX >= 0 )
				{
					var dist:int = Math.abs( _x - lastX );
					var ly:int = heightMap[lastX];
					
					if ( _x > lastX )
					{
						for ( var i:int = 1; i <= dist; i++ )
						{
							var percent:Number = i / dist;
							var interp:int = ly + ( _y - ly ) * percent;
							heightMap[ lastX + i ] = interp;
						}
					}
					else
					{
						for ( i = dist; i >= 1; i-- )
						{
							percent = ( i) / dist;
							interp = ly + ( _y - ly ) * percent;
							heightMap[ lastX - i ] = interp;
						}
					}
				}
				else
				{
					heightMap[_x] = _y;
				}
				
				lastX = _x;
			}
			
			render();
		}
	}
}