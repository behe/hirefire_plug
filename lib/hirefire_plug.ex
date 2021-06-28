defmodule HirefirePlug do
  import Plug.Conn

  def init(options) do
    options =
      with {:ok, token_fun} when is_function(token_fun, 0) <- Keyword.fetch(options, :token) do
        options
      else
        :error ->
          raise """
          A :token function must be configured for HirefirePlug

          plug HirefirePlug, token: &MyApp.hirefire_token/0
          """

        {:ok, _token_fun} ->
          raise """
          The configured :token must be a function for HirefirePlug

          plug HirefirePlug, token: &MyApp.hirefire_token/0
          """
      end

    with {:ok, worker_jobs} when is_map(worker_jobs) <- Keyword.fetch(options, :worker_jobs) do
      Enum.map(worker_jobs, fn {_key, fun} ->
        unless is_function(fun, 0) do
          raise """
          The configured :worker_jobs map values must be functions for HirefirePlug

          plug HirefirePlug, worker_jobs: %{worker: &MyApp.worker_job_length/0}
          """
        end
      end)
    else
      :error ->
        raise """
        A :worker_jobs map must be configured for HirefirePlug

        plug HirefirePlug, worker_jobs: %{worker: &MyApp.worker_job_length/0}
        """
    end

    options
  end

  def call(conn = %{path_info: ["hirefire", path_token, "info"]}, options) do
    token_fun = Keyword.fetch!(options, :token)
    worker_jobs = Keyword.fetch!(options, :worker_jobs)

    if path_token == token_fun.() do
      job_queues =
        Enum.map(worker_jobs, fn {name, quantity_fun} ->
          %{"name" => name, "quantity" => quantity_fun.()}
        end)

      json(conn, job_queues)
    else
      conn
    end
  end

  def call(conn, _options), do: conn

  defp json(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(data))
    |> halt
  end
end
