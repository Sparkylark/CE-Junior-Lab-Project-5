package p6_main;

import java.awt.Canvas;
import java.awt.Color;
import java.awt.Graphics;

public class PixelCanvas extends Canvas {
    static Graphics gr;
    @Override
    public void paint(Graphics g) {
        super.paint(g);
        int currentSize = this.getHeight() / 256;
        
        for(int x=0; x<255; x++){
        	for(int y=0; y<255; y++){
            	g.setColor(Main.pixelMatrix[x][y]);
            	g.drawRect(x*(Main.size+1), y*(Main.size+1),1,1);
        	}
        }
    }
}