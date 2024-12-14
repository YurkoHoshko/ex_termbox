defmodule ExTermbox.Bindings do
  @moduledoc """
  Provides low-level bindings to the termbox2 library using Zigler/Zig.
  This module implements the core termbox functionality for terminal manipulation
  and rendering.
  """

  alias ExTermbox.Cell
  alias ExTermbox.Position

  use Zig,
    otp_app: :ex_termbox,
    c: [
      link_lib: "../../c_src/termbox2/libtermbox2.a",
      include_dirs: "../../c_src/termbox2"
    ],
    nifs: [
      :init,
      :shutdown,
      :select_input_mode,
      :select_output_mode,
      :width,
      :height,
      :clear,
      :set_clear_attributes,
      :present,
      :set_cursor,
      :change_cell,
      poll_async: [:threaded, :dirty_io]
    ],
    callbacks: [on_load: :load_fn]

  ~Z"""
  const beam = @import("beam");
  const c = @cImport(@cInclude("termbox2.h"));
  const e = @import("erl_nif");
  const root = @import("root");
  const std = @import("std");

  // Global state
  var running: bool = false;
  var polling_enabled: bool = false;
  var mutex: ?*e.ErlNifMutex = null;

  // On Load

  pub fn load_fn(_: ?*?*u32, _: u32) !void {
      mutex = e.enif_mutex_create(@constCast("extb-poll-mutex"));
  }

  // Helper functions
  fn ok() beam.term {
      return beam.make(.ok, .{});
  }

  fn ok_tuple(value: anytype) beam.term {
      return beam.make(.{ .ok, value }, .{});
  }

  fn error_tuple(reason: @TypeOf(.enum_literal)) beam.term {
      return beam.make(.{ .@"error", reason }, .{});
  }

  // Initialize termbox
  pub fn init() beam.term {
      _ = e.enif_mutex_lock(mutex);
      defer _ = e.enif_mutex_unlock(mutex);
      if (running) {
          return error_tuple(.already_running);
      }

      const code = c.tb_init();
      if (code == 0) {
          running = true;
          return ok();
      }
      return error_tuple(.could_not_start);
  }

  // Get terminal width
  pub fn width() beam.term {
      if (!running) {
          return error_tuple(.not_running);
      }
      const w = c.tb_width();
      return ok_tuple(w);
  }

  // Get terminal height
  pub fn height() beam.term {
      if (!running) {
          return error_tuple(.not_running);
      }
      const h = c.tb_height();
      return ok_tuple(h);
  }

  // Clear the terminal
  pub fn clear() beam.term {
      if (!running) {
          return error_tuple(.not_running);
      }
      _ = c.tb_clear();
      return ok();
  }

  // Set clear attributes
  pub fn set_clear_attributes(fg: u32, bg: u32) beam.term {
      if (!running) {
          return error_tuple(.not_running);
      }
      _ = c.tb_set_clear_attrs(@truncate(fg), @truncate(bg));
      return ok();
  }

  // Present changes to the terminal
  pub fn present() beam.term {
      if (!running) {
          return error_tuple(.not_running);
      }
      _ = c.tb_present();
      return ok();
  }

  // Set cursor position
  pub fn set_cursor(x: i32, y: i32) beam.term {
      if (!running) {
          return error_tuple(.not_running);
      }
      _ = c.tb_set_cursor(@truncate(x), @truncate(y));
      return ok();
  }

  // Change cell attributes
  pub fn change_cell(x: i32, y: i32, ch: u32, fg: u32, bg: u32) beam.term {
      if (!running) {
          return error_tuple(.not_running);
      }
      _ = c.tb_set_cell(x, y, ch, @truncate(fg), @truncate(bg));
      return ok();
  }

  // Select input mode
  pub fn select_input_mode(mode: i32) beam.term {
      const result = c.tb_set_input_mode(mode);
      return ok_tuple(result);
  }

  // Select output mode
  pub fn select_output_mode(mode: i32) beam.term {
      const result = c.tb_set_output_mode(mode);
      return ok_tuple(result);
  }

  // Shutdown termbox
  pub fn shutdown() beam.term {
      _ = e.enif_mutex_lock(mutex);
      defer _ = e.enif_mutex_unlock(mutex);
      if (!running) {
          return error_tuple(.not_running);
      }
      _ = c.tb_shutdown();
      running = false;
      return ok();
  }

  // Poll
  pub fn poll_async(recipient_pid: beam.pid) !void {
      defer {
          beam.send(recipient_pid, .killed, .{}) catch {};
      }

      var poll_result: c_int = 0;
      while (running) {
          var event: c.tb_event = undefined;

          poll_result = c.tb_peek_event(&event, 0);
          if (poll_result == 0) {
              const payload = beam.make(.{ .event, event }, .{});
              _ = try beam.send(recipient_pid, payload, .{});
          }

          try beam.yield();
      }
  }
  """

  @spec put_cell(Cell.t()) :: :ok | {:error, :not_running}
  def put_cell(%Cell{position: %Position{x: x, y: y}, ch: ch, fg: fg, bg: bg}) do
    change_cell(x, y, ch, fg, bg)
  end
end
