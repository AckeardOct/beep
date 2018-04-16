import std.stdio;
import std.string;
import std.conv;
import std.ascii;
import std.datetime;
import std.file;
import std.path;
import std.process;
import core.thread;

import deimos.ncurses;

const string SOUND_PATH = "~/.config/beep/beep.wav";

void playSound()
{
    if(!exists(expandTilde(SOUND_PATH))) {
        writeln("[ERROR] need sound:", SOUND_PATH);
        return;
    }

    string cmd = "mpv --idle --no-audio-display " ~ SOUND_PATH ~ " > /dev/null 2> /dev/null";
    spawnShell(cmd);    
    writeln("BEEP");
}

Duration calcArgs(string args)
{
    Duration ret;
    args = args.toLower();
    char last = args[$-1];

    if(!isAlpha(last)) {
        ret += dur!"seconds"(to!int(args));
        return ret;   
    }

    if(args.length < 2 )
        return ret;
    string number = args[0 .. $-1];
    if(!number.isNumeric())
        return ret;        
    int num = to!int(number);
    if(num <= 0)
        return ret;
    switch(last)
    {
        case 'h':             
            ret += dur!"hours"(num);
            break;
        case 'm': 
            ret += dur!"minutes"(num);
            break;        
        case 's': 
            ret += dur!"seconds"(num);
            break;
        default:
            return ret;
    }        

    return ret;
}

class Timer
{
    SysTime startTime;
    Duration allTime;
    Duration leftTime;

    this(Duration timer) {
        startTime = Clock.currTime;
        allTime = timer;
        leftTime = timer;
    }

    bool update()
    {
        Duration timeElapsed = Clock.currTime - startTime;
        leftTime = allTime - timeElapsed;        

        if(leftTime <= dur!"seconds"(0))
            return false;

        return true;
    }

    int getPercent()
    {
        long left = to!long(leftTime.total!"seconds"());
        long all = to!long(allTime.total!"seconds"());        
        return 100 - (100 * left / all);
    }
}

void view(Timer timer)
{    
    initscr();     // initialize the screen
    scope (exit)
    endwin();  // always exit cleanly


    while(timer.update()) 
    {
        string percent = to!string(timer.getPercent());
        string allTime = "All: " ~ timer.allTime.toString();
        string leftTime = "Left: " ~ timer.leftTime.toString();

        clear();
        printw(toStringz(percent));
        printw("%\n");
        printw(toStringz(allTime));
        printw("\n");
        printw(toStringz(leftTime));
        printw("\n");

        refresh();
        Thread.sleep( dur!("msecs")( 500 ) );
    }
        
    endwin();                    
}

void main(string[] args)
{
    if(args.length > 1) {
        auto timer = new Timer(calcArgs(args[1]));
        view(timer);
    }
    
    playSound();
}