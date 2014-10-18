package
{
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	
	public class SeekBar extends Sprite {
		
		var btnWidth:int = 20;
		var btnHeight:int = 40;
		var btnX:int = 0;
		var btnY:int = 0;
		var barLength:int = 100;
		
		function SeekBar(w:int, h:int, l:int) {
			btnWidth = w;
			btnHeight = h;
			barLength = l;
		}

		var seekBar:Sprite = new Sprite();
		var seekBuuton:Sprite = new Sprite();

		function setBarPosition(position:Number) {
			seekBuuton.x = barLength*position;
		}

		function getBarPosition0():Number{
			return seekBuuton.x/barLength;
		}
		function getBarPosition():Number {
			return seekBuuton.x;
		}
		

		function hitButton(x:Number, y:Number):Boolean {
			return seekBuuton.hitTestPoint(x, y);
		}

		function move(x:Number){
			seekBuuton.x = seekBuuton.x + x;
			if(0 > seekBuuton.x) {
				seekBuuton.x = 0;
			} 
			else if(barLength<seekBuuton.x){
				seekBuuton.x = barLength;
			}
		}
		function init() {

			seekBar.graphics.beginFill(0xffffff);
			seekBar.graphics.drawRect(0, 0, barLength, btnHeight/4);
			seekBar.x = x;
			seekBar.y = btnHeight*3/8;
			addChild(seekBar);

			var barWitdth = width-(x+btnWidth);
			seekBuuton.graphics.beginFill(0xaaffaa);
			seekBuuton.graphics.drawRect(0, 0, btnWidth, btnHeight);
			seekBuuton.x = btnX;
			seekBuuton.y = 0;
			addChild(seekBuuton);
			
			var isOn:Boolean = false;
		}
	}
}