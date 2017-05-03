package p6_main;

import javax.imageio.ImageIO;
import javax.swing.JFrame;

import com.fazecast.jSerialComm.*;

import java.awt.Canvas;
import java.awt.Color;
import javax.swing.JLabel;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.swing.JPanel;

public class Main {
	static Color[][] pixelMatrix;
	static PixelCanvas canvas;
	static int Red=0, Grn=0, Blu=0;
	static String state = "waitForPre";
	static int ASCIIcount = 0;
	static String ASCIIstring = "";
	static int width = 1;
	static int size = 0;
	static int x, y;
	static int currentSave = 1;
	public static void main(String[] args) {
		JFrame main = new JFrame();
		main.setTitle("Etch-a-Sketch");
		main.getContentPane().setLayout(null);
		//Create status labels and color panel
		JLabel widthLabel = new JLabel("Cursor Width: 1");
		widthLabel.setFont(new Font("Tahoma", Font.PLAIN, 14));
		widthLabel.setBounds(264, 615, 124, 24);
		main.getContentPane().add(widthLabel);
		
		JLabel colorLabel = new JLabel("Draw Color: ");
		colorLabel.setFont(new Font("Tahoma", Font.PLAIN, 14));
		colorLabel.setBounds(567, 615, 87, 24);
		main.getContentPane().add(colorLabel);
		
		JLabel commandLabel = new JLabel("Current Command: ");
		commandLabel.setFont(new Font("Tahoma", Font.PLAIN, 14));
		commandLabel.setBounds(378, 656, 241, 24);
		main.getContentPane().add(commandLabel);
		
		JPanel colorPanel = new JPanel();
		colorPanel.setBackground(Color.BLACK);
		colorPanel.setBounds(644, 615, 25, 24);
		main.getContentPane().add(colorPanel);
		main.setResizable(false);
		main.setSize(960, 720);
		main.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		//Fill pixelMatrix with white
		pixelMatrix = new Color[256][256];
		for(int x=0; x<256; x++){
			for(int y=0; y<256; y++){
				pixelMatrix[x][y] = new Color(255, 255, 255);
			}
		}
		//Make a canvas for drawing in
		canvas = new PixelCanvas();
		canvas.setBounds(352, 182, 256, 256);
		main.add(canvas);
		main.setVisible(true);
		//Check that hardware is connected
		if (SerialPort.getCommPorts().length == 0){
			System.out.println("No Hardware Connected");
			commandLabel.setText("NO HARDWARE CONNECTED");
		}
		else{
			//get and open a comm port with 115,200 baud
			SerialPort comPort = SerialPort.getCommPorts()[0];
			comPort.openPort();
		    comPort.setBaudRate(115200);
			comPort.addDataListener(new SerialPortDataListener() {
			   @Override
			   public int getListeningEvents() { return SerialPort.LISTENING_EVENT_DATA_AVAILABLE; }
			   @Override
			   public void serialEvent(SerialPortEvent event)
			   {
			      if (event.getEventType() != SerialPort.LISTENING_EVENT_DATA_AVAILABLE)
			         return;
			      byte[] newData = new byte[comPort.bytesAvailable()];
			      int numRead = comPort.readBytes(newData, newData.length);
			      for (int index=0; index<numRead; index++){
			    	  byte data = newData[index];
			    	  int unsigned = data & 0xFF;
			    	  //this is a pseudo state machine for interpreting the input bytes from the hardware
			    	  switch (state){
			    	  case "waitForPre":
			    		  if(unsigned == 85){ //Preamble
			    			  state = "Preamble";
			    		  }
		    			  break;
			    	  case "Preamble":
			    		  if(unsigned == 240){ //Erase
			    			  for(int x=0; x<256; x++){
			    				  for(int y=0; y<256; y++){
			    					  pixelMatrix[x][y] = new Color(255, 255, 255);
			    				  }
			    			  }
			    			  canvas.repaint();
			    			  state = "waitForPre";
			    		  }else if(unsigned == 51){ //ASCII Update
			    			  ASCIIcount = 0;
			    			  ASCIIstring = "";
			    			  state = "ASCIIupdate";
			    		  }else if(unsigned == 170){ //Status Update
			    			  ASCIIstring = "";
			    			  commandLabel.setText("Current Command:");
			    			  state = "getRed";
			    		  }else if(unsigned == 204){ //Coord Update
			    			  state = "getX";
			    		  }else if(unsigned == 153){ //Save
			    			  BufferedImage saveImage = new BufferedImage(canvas.getWidth(), canvas.getHeight(), BufferedImage.TYPE_INT_RGB);
			    			  canvas.paint(saveImage.getGraphics());
			    			  try {
								ImageIO.write(saveImage, "png", new File("C:\\Users\\benlo\\Desktop\\etchy" + currentSave + ".png"));
								//CHANGE THIS PATH IF YOU WANT TO SAVE IT SOMEWHERE ELSE
							} catch (IOException e) {
								// TODO Auto-generated catch block
								e.printStackTrace();
							}
					    	  System.out.println("Saved sketch to Desktop as \"etchy" + currentSave + ".png\"");
					    	  currentSave++;
			    		  }else state = "waitForPre"; //bad opcode
			    		  
			    		  break;
			    	  case "ASCIIupdate":
			    		  ASCIIstring += (char) data;
			    		  if(ASCIIcount < 6) ASCIIcount++;
			    		  else{
			    			  commandLabel.setText("Current Command: "+ ASCIIstring);
			    			  state = "waitForPre";
			    		  }
		    			  break;
			    	  case "getRed":
			    		  Red = unsigned;
			    		  state = "getGrn";
		    			  break;
			    	  case "getGrn":
			    		  Grn = unsigned;
			    		  state = "getBlu";
		    			  break;
			    	  case "getBlu":
			    		  Blu = unsigned;
			    		  colorPanel.setBackground(new Color(Red, Grn, Blu));
			    		  state = "getCurSize";
		    			  break;
			    	  case "getCurSize":
			    		  width = (data >> 5) & 0x07;
			    		  widthLabel.setText("Cursor Width: "+width);
			    		  if(((data >> 4) & 0x01) != size){
			    			  size = (data >> 4) & 0x01;
			    			  resize();
			    		  }
			    		  state = "getX";
		    			  break;
			    	  case "getX":
			    		  x = unsigned;
			    		  state = "getY";
		    			  break;
			    	  case "getY":
			    		  y = unsigned;
			    		  placePixel();
			    		  state = "waitForPre";
		    			  break;
			    	  }
			      }
			   }
			});
		}
	}
	//This function resizes the sketchboard when "Size" changes between 0 and 1
	public static void resize(){
		if(size == 0){
			canvas.setBounds(352, 182, 256, 256);
		}else{
			canvas.setBounds(224,  54,  512,  512);
		}
	}
	
	//this function determines how to draw a pixel with the current coordinates, size, and color, and then updates colorMatrix and the drawing canvas
	public static void placePixel(){
		int minX, maxX, minY, maxY;
		if(width == 1){ //find pixel bounds using width and current x and y
			minX = x;
			maxX = x;
			minY = y;
			maxY = y;
		}else if(width == 2){
			minX = x;
			maxX = x + 1;
			minY = y;
			maxY = y + 1;
		}else if(width == 3){
			minX = x - 1;
			maxX = x + 1;
			minY = y - 1;
			maxY = y + 1;
		}else if(width == 4){
			minX = x - 1;
			maxX = x + 2;
			minY = y - 1;
			maxY = y + 2;
		}else if(width == 5){
			minX = x - 2;
			maxX = x + 2;
			minY = y - 2;
			maxY = y + 2;
		}else if(width == 6){
			minX = x - 2;
			maxX = x + 3;
			minY = y - 2;
			maxY = y + 3;
		}else{
			minX = x - 3;
			maxX = x + 3;
			minY = y - 3;
			maxY = y + 3;
		}
		if(minX < 0) minX = 0; //bring bounds within the range 0 to 255
		if(minY < 0) minY = 0;
		if(maxX > 255) maxX = 255;
		if(maxY > 255) maxY = 255;
		Graphics g = canvas.getGraphics(); //get canvas state to modify
		g.setColor(new Color(Red, Grn, Blu));
		for(int curX = minX; curX <= maxX; curX++){ //update the color matrix
			for(int curY = minY; curY <= maxY; curY++){
				pixelMatrix[curX][curY] = g.getColor();
				g.drawRect(curX*(size+1), curY*(size+1), 1, 1);
			}
		}
	}
}
