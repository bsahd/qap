local ftcsv = require 'ftcsv'
local utf8 = require "utf8"

local function string_to_codepoint_array(s)
  local arr = {}
  for _, cp in utf8.codes(s) do
    table.insert(arr, cp)
  end
  return arr
end

local function levenshteinDistance(a, b)
  local m = #a;
  local n = #b;
  local dp = {};
  for i = 1, m + 1 do
    dp[i] = {};
  end
  for i = 1, m + 1 do
    dp[i][1] = i - 1;
  end
  for j = 1, n + 1 do
    dp[1][j] = j - 1;
  end
  for i = 1, m do
    for j = 1, n do
      local cost;
      if a[i] == b[j] then
        cost = 0;
      else
        cost = 2;
      end
      dp[i + 1][j + 1] = math.min(
        dp[i][j + 1] + 1,
        dp[i + 1][j] + 1,
        dp[i][j] + cost
      );
    end
  end
  return dp[#a + 1][#b + 1];
end

local qas = ftcsv.parse(arg[1])

local function searchQuestions(q)
  local qa = string_to_codepoint_array(string.lower(q))
  local distances = {};
  for i, e in ipairs(qas) do
    local eq = string_to_codepoint_array(string.lower(e.question))
    table.insert(distances, {
      question = e.question,
      answer = e.answer,
      normalized_distance = levenshteinDistance(qa, eq) / (#qa + #eq)
    });
  end
  table.sort(distances, function(a, b) return a.normalized_distance < b.normalized_distance end)
  return distances
end

-- print(searchQuestions(arg[1]))

local quinku = require "quinku"
local JSON = require "lunajson"
local socket_url = require("socket.url")

function table.slice(tbl, first, last)
  local sliced = {}
  for i = first or 1, last or #tbl do
    sliced[#sliced + 1] = tbl[i]
  end
  return sliced
end

local function html_encode(s)
  s = s:gsub("&", "&amp;") -- 最初に & を変換しないと、他のエンティティが二重エンコードされる
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  s = s:gsub("'", "&#39;") -- または '&apos;'。HTML5では '&apos;' が標準だが、互換性を考えると &#39; も一般的。
  return s
end

local function handler(request)
  local q = socket_url.unescape((request.get["q"] or ""):gsub("%+", " "))
  local response = {
    status = 404,
    headers = { ["Content-Type"] = "text/plain; charset=UTF-8" },
    body = [[Not Found]]
  }
  if request.path == "/api" then
    response = {
      status = 200,
      headers = { ["Content-Type"] = "application/json; charset=UTF-8" },
    }
    if q == "" then
      response.body = "[]"
      return response
    end
    local distances = searchQuestions(q)
    response.body = JSON.encode(table.slice(distances, 1, 5))
    return response
  elseif request.path == "/" then
    response = {
      status = 200,
      headers = { ["Content-Type"] = "text/html; charset=UTF-8" },
      body = [[<!DOCTYPE html>
<html>
  <head>
    <title>QAP Web UI</title>
  </head>
  <body>
    <form method="GET" action="/">
      <input name="q" value="]] .. (html_encode(q)) .. [[">
      <button>Question</button>
    </form>
]]
    }
    if q == "" then
      response.body = response.body .. "No Query"
    else
      local distances = searchQuestions(q)
      response.body = response.body ..
          [[    <table>
      <thead>
        <tr>
          <td>Question</td>
          <td>Answer</td>
          <td>Relevance</td>
        </tr>
      </thead>
      <tbody>]]
      for i, v in ipairs(table.slice(distances, 1, 5)) do
        response.body = response.body ..
            "\n" .. [[
        <tr>
          <td>]] .. v.question .. [[</td>
          <td>]] .. v.answer .. [[</td>
          <td>]] .. string.format("%f", (1 - v.normalized_distance)) .. [[</td>
        </tr>]]
      end
      response.body = response.body .. "\n      </tbody>\n    </table>"
    end
    response.body = response.body .. "\n  </body>\n</html>"
  else
    print("Not Found")
  end
  response.body = response.body .. "\n"
  return response
end

print("Listening on http://localhost:8080/")
quinku.run({
  ip = "0.0.0.0",
  port = 8080,
  handler = handler
})
