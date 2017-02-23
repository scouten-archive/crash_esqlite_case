%%-------------------------------------------------------------------
%%
%% Copyright (c) 2016, James Fish <james@fishcakez.com>
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License. You may obtain
%% a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied. See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%%-------------------------------------------------------------------
%% @private
-module(sbroker_sup).

-behaviour(supervisor).

%% public API

-export([start_link/0]).

%% supervisor API

-export([init/1]).

%% public API

-spec start_link() -> {ok, Pid} when
      Pid :: pid().
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% supervisor API

init([]) ->
    ServerSup = {sbroker_server_sup, {sbroker_server_sup, start_link, []},
                 permanent, infinity, supervisor, [sbroker_server_sup]},
    UserSup = {sbroker_user_sup,
               {sbroker_user_sup, start_link, []},
               permanent, infinity, supervisor, [sbroker_user_sup]},
    {ok, {{rest_for_one, 3, 300}, [ServerSup, UserSup]}}.
