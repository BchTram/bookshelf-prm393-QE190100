import java.lang.reflect.*;
import java.nio.file.*;
import java.util.*;
import com.google.re2j.Pattern;

// Diagnose emulator RE2/JDK Unicode table differences without entering minFoldRune loops.
class ProbeUnicode {
  public static void main(String[] args) throws Exception {
    var method=Class.forName("com.google.re2j.Unicode").getDeclaredMethod("simpleFold",int.class);
    method.setAccessible(true);
    var broken=new TreeSet<Integer>();
    for(int c=65;c<=66639;c++) {
      int next=c; boolean cycle=false;
      for(int n=0;n<32;n++) {next=(int)method.invoke(null,next); if(next==c) {cycle=true;break;}}
      if(!cycle) broken.add(c);
    }
    var incompatible=new TreeSet<Integer>(broken);
    for(String line:Files.readAllLines(Path.of(".firebase/folds.tsv"))) {
      String[] pair=line.split("\t"); int source=Integer.parseInt(pair[0]), target=Integer.parseInt(pair[1]);
      if(broken.contains(source)||broken.contains(target)) {incompatible.add(source);incompatible.add(target);continue;}
      String original=new String(Character.toChars(source)), canonical=new String(Character.toChars(target));
      if(!Pattern.compile("(?i)\\Q"+original+"\\E").matcher(canonical).matches()) {
        incompatible.add(source);incompatible.add(target);
      }
    }
    Files.writeString(Path.of(".firebase/re2-incompatible.json"), incompatible.toString());
    System.out.println("RE2 incompatible codepoints: "+incompatible);
  }
}
