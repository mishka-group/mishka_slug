# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

# `mix test --include sync_integration` also runs the tests that need the network.
ExUnit.start(exclude: [:sync_integration])
