local ftcsv = require 'ftcsv'
local utf8 = require "utf8"

local function string_to_codepoint_array(s)
  local arr = {}
    for _, cp in utf8.codes(s) do
      table.insert(arr, cp)
    end
  return arr
end

local function createDPTable(a, b)
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
  return dp;
end
local function levenshteinDistance(a, b)
  return createDPTable(a, b)[#a + 1][#b + 1];
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
      relevance = levenshteinDistance(qa, eq) / (#qa + #eq)
    });
  end
  table.sort(distances, function(a, b) return a.relevance < b.relevance end)
  if #distances == 0 then
    return "該当する質問が見つかりませんでした。"
  end
  local best_match = distances[1];
  local similarity_percentage = (1 - (best_match.relevance)) * 100;
  return string.format("%s\n→%s\n(類似度:%.0f%%)",
    best_match.question, best_match.answer, similarity_percentage)
end

print(searchQuestions(arg[2]))
