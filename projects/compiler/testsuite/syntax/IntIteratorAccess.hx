package syntax;

import unit.Assert;

class IntIteratorAccess {
  public function new() {}
  
  public function testIterator() {
    var ref = 5;
    var range = 5...10;
    for(i in range) {
      Assert.equals(ref, i);
      ref++;
    }
  }
}