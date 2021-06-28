defmodule HirefirePlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  describe "init" do
    test "init token from token function" do
      token_fun = fn -> "hirefire-token" end
      worker_jobs = %{queue: fn -> 24 end, worker: fn -> 42 end}

      assert HirefirePlug.init(token: token_fun, worker_jobs: worker_jobs) == [
               token: token_fun,
               worker_jobs: worker_jobs
             ]
    end

    test "requires token" do
      assert_raise RuntimeError,
                   """
                   A :token function must be configured for HirefirePlug

                   plug HirefirePlug, token: &MyApp.hirefire_token/0
                   """,
                   fn ->
                     HirefirePlug.init([])
                   end
    end

    test "requires token function" do
      assert_raise RuntimeError,
                   """
                   The configured :token must be a function for HirefirePlug

                   plug HirefirePlug, token: &MyApp.hirefire_token/0
                   """,
                   fn -> HirefirePlug.init(token: "hirefire-token") end
    end

    test "requires worker jobs" do
      assert_raise RuntimeError,
                   """
                   A :worker_jobs map must be configured for HirefirePlug

                   plug HirefirePlug, worker_jobs: %{worker: &MyApp.worker_job_length/0}
                   """,
                   fn ->
                     HirefirePlug.init(token: fn -> "hirefire-token" end)
                   end
    end

    test "requires worker job map value functions" do
      assert_raise RuntimeError,
                   """
                   The configured :worker_jobs map values must be functions for HirefirePlug

                   plug HirefirePlug, worker_jobs: %{worker: &MyApp.worker_job_length/0}
                   """,
                   fn ->
                     HirefirePlug.init(
                       token: fn -> "hirefire-token" end,
                       worker_jobs: %{worker: 42}
                     )
                   end
    end
  end

  describe "call" do
    test "get current job queue lengths for our workers" do
      conn =
        conn(:get, "/hirefire/hirefire-token/info")
        |> HirefirePlug.call(
          token: fn -> "hirefire-token" end,
          worker_jobs: %{queue: fn -> 24 end, worker: fn -> 42 end}
        )

      assert conn.halted == true
      assert conn.status == 200

      assert Jason.decode!(conn.resp_body) == [
               %{"name" => "queue", "quantity" => 24},
               %{"name" => "worker", "quantity" => 42}
             ]
    end

    test "pass through if the token does not match" do
      conn =
        conn(:get, "/hirefire/wrong-token/info")
        |> HirefirePlug.call(
          token: fn -> "hirefire-token" end,
          worker_jobs: %{queue: fn -> 24 end, worker: fn -> 42 end}
        )

      assert conn.halted == false
    end

    test "pass through if the path does not match" do
      conn =
        conn(:get, "/wrong/path")
        |> HirefirePlug.call(
          token: fn -> "hirefire-token" end,
          worker_jobs: %{queue: fn -> 24 end, worker: fn -> 42 end}
        )

      assert conn.halted == false
    end
  end
end
