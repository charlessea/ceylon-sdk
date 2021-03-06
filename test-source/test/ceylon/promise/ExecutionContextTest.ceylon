import ceylon.test {
  test
}
import ceylon.promise {
  Deferred,
  ExecutionContext
}


shared class ExecutionContextTest() extends AsyncTestBase() {
  
  variable Integer serial = 0;

  class CustomExecutionContext() satisfies ExecutionContext {
    shared Integer id = serial++;    
    shared actual void run(void task()) {
      task();
    }
    shared actual ExecutionContext childContext() => CustomExecutionContext();
  }
  
  shared test void testChildContext() {
    value p1 = Deferred<String>(CustomExecutionContext()).promise;
    value p2 = p1.compose((String s) => s);
    value p3 = p1.compose((String s) => s);    
    assert(is CustomExecutionContext c1 = p1.context);
    assert(is CustomExecutionContext c2 = p2.context);
    assert(is CustomExecutionContext c3 = p3.context);
    assertEquals(0, c1.id);
    assertEquals(1, c2.id);
    assertEquals(2, c3.id);
    testComplete();
  }

  shared test void testUseCustomContextOnDeferred() {
    variable Integer count = 0;
    object myExecutionContext satisfies ExecutionContext {
      shared actual void run(void task()) {
        assertEquals(count++, 0);
        task();
        assertEquals(count++, 2);
        testComplete();
      }
      shared actual ExecutionContext childContext() => this;
    }
    value deferred = Deferred<String>(myExecutionContext);
    deferred.promise.onComplete {
      void onFulfilled(String s) {
        assertEquals(count++, 1);
        assertEquals(s, "hello");
      }
    };
    deferred.resolve("hello");
  }
  
  shared test void testCustomContextPropagation() {
    variable Boolean onContext = false;
    object myContext satisfies ExecutionContext {
      shared actual void run(void task()) {
        onContext = true;
        task();
        onContext = false;
      }
      shared actual ExecutionContext childContext() => this;
    }
    value deferred = Deferred<String>(myContext);
    value promise = deferred.promise.compose {
      String onFulfilled(String s) {
        assertEquals(onContext, true);
        assertEquals(s, "hello");
        return "bye";
      }
    };
    promise.onComplete {
      void onFulfilled(String s) {
        assertEquals(onContext, true);
        assertEquals(s, "bye");
        testComplete();
      }
    };
    deferred.resolve("hello");
  }
}