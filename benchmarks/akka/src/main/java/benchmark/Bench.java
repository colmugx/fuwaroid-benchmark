package benchmark;

import akka.actor.typed.ActorSystem;
import akka.actor.typed.Behavior;
import akka.actor.typed.javadsl.Behaviors;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

public final class Bench {
  interface Command {}

  static final class Tick implements Command {
    static final Tick INSTANCE = new Tick();
    private Tick() {}
  }

  static final class Barrier implements Command {
    final CompletableFuture<Long> done;
    Barrier(CompletableFuture<Long> done) { this.done = done; }
  }

  static Behavior<Command> counter() {
    return Behaviors.setup(context -> {
      final long[] count = new long[] {0L};
      return Behaviors.receive(Command.class)
          .onMessage(Tick.class, tick -> {
            count[0]++;
            return Behaviors.same();
          })
          .onMessage(Barrier.class, barrier -> {
            barrier.done.complete(count[0]);
            return Behaviors.same();
          })
          .build();
    });
  }

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("usage: akka-bench <messages>");
      System.exit(2);
    }
    final long n = Long.parseLong(args[0]);
    if (n < 0) {
      System.err.println("invalid message count");
      System.exit(2);
    }

    final ActorSystem<Command> system = ActorSystem.create(counter(), "fuwaroid-benchmark");
    for (long i = 0; i < n; i++) {
      system.tell(Tick.INSTANCE);
    }

    final CompletableFuture<Long> done = new CompletableFuture<>();
    system.tell(new Barrier(done));
    final long got = done.get(60, TimeUnit.SECONDS);
    if (got != n) {
      throw new IllegalStateException("count mismatch: want=" + n + " got=" + got);
    }

    system.terminate();
    system.getWhenTerminated().toCompletableFuture().get(30, TimeUnit.SECONDS);
  }
}
