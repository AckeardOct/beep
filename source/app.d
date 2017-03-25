import std.stdio;
import std.string;
import std.ascii;
import std.conv;
import std.datetime;
import core.thread;
import std.process;
import std.file;
import std.path;

uint wait_s = 0;

immutable string BEEP_WAV = "~/.local/share/beep/beep.wav";

bool convertString(string _str)
{
    assert(!_str.empty());
    _str = _str.toLower();
    char last = _str[$-1];
    if(!isAlpha(last)) {
        wait_s += to!int(_str);
        return true;   
    } 
        
    if(_str.length < 2 )
        return false;
    string number = _str[0 .. $-1];
    if(!number.isNumeric())
        return false;        
    int num = to!int(number);
    if(num <= 0)
        return false;
    switch(last) {
        case 'h': 
            wait_s += num * 60 * 60;
            break;
        case 'm': 
            wait_s += num * 60;
            break;        
        case 's': 
            wait_s += num;
            break;
        default:
            return false;
    }        
    return true;
}

int main(string[] args)
{         
    if(!exists(expandTilde(BEEP_WAV))) {
        writeln("[ERROR] need sound:", BEEP_WAV);
        return 1;
    }
    
    MonoTime start = MonoTime.currTime;    
    string head;
    
    if(args.length > 1) 
    {        
        foreach(arg; args[1 .. $])
            if(!convertString(arg)){
                writeln("[ERROR] wrong argument: ", arg);
                return 2;
            }                      
    }
        
    while(true)
    {                                
        MonoTime after = MonoTime.currTime;  
        Duration timeElapsed = after - start;
        if(timeElapsed >= wait_s.seconds())
            break;
        Duration last = wait_s.seconds() - timeElapsed;
        string lastStr = last.toString();        
        writeln("Last: ", lastStr);        
        Thread.sleep( dur!("msecs")( 800 ) );
    }                                            
    	
    string cmd = "aplay " ~ BEEP_WAV;
    writeln(cmd);
    executeShell(cmd);    
    return 0;
}

unittest {
    assert(convertString("10") == true);
    assert(wait_s == 10);
    assert(convertString("1h") == true);
    assert(wait_s == 3610);
    assert(convertString("1m") == true);
    assert(wait_s == 3670);
    assert(convertString("1s") == true);
    assert(wait_s == 3671);
}
