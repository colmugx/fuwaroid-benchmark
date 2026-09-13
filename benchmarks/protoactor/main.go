package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/asynkron/protoactor-go/actor"
)

type tick struct{}
type barrier struct{}

type counter struct { count int64 }

func (c *counter) Receive(ctx actor.Context) {
	switch ctx.Message().(type) {
	case *actor.Started:
		return
	case tick:
		c.count++
	case barrier:
		ctx.Respond(c.count)
	}
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: proto_bench <messages>")
		os.Exit(2)
	}
	n, err := strconv.ParseInt(os.Args[1], 10, 64)
	if err != nil || n < 0 {
		fmt.Fprintln(os.Stderr, "invalid message count")
		os.Exit(2)
	}

	system := actor.NewActorSystem()
	root := system.Root
	pid := root.Spawn(actor.PropsFromProducer(func() actor.Actor { return &counter{} }))
	msg := tick{}
	for i := int64(0); i < n; i++ {
		root.Tell(pid, msg)
	}

	future := root.RequestFuture(pid, barrier{}, 60*time.Second)
	result, err := future.Result()
	if err != nil { panic(err) }
	got, ok := result.(int64)
	if !ok || got != n {
		panic(fmt.Sprintf("count mismatch: want=%d got=%v", n, result))
	}
	root.Stop(pid)
}
