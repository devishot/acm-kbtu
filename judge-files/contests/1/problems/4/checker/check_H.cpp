#define EJUDGE
#define NOFOOTER
#include "testlib.h"
#include <algorithm>
#include <map>
#include <set>
#include <vector>
#include <iostream>

using std::string;
using std::vector;

bool checkLine(const string &s) {
  bool result = true;
  if (s.size() != 4) {
    result = false;
  } else {
    for (int i = 0; i < 4; ++i) {
      if (s[i] != '.' && s[i] != '*') {
        result = false;
      }
    }
  }
  return result;
}

int dfs(vector<vector<int> > *a, int x, int y) {
  const int dx[4] = {1, 0, -1, 0};
  const int dy[4] = {0, 1, 0, -1};
  (*a)[x][y] = 2;
  int result = 1;
  for (int d = 0; d < 4; ++d) {
    if ((*a)[x + dx[d]][y + dy[d]] == 1) {
      result += dfs(a, x + dx[d], y + dy[d]);
    }
  }
  return result;
}

int main(int argc, char* argv[]){
setName("Checker for problem H");
    registerTestlibCmd(argc, argv);

    int p = inf.readInteger();
    int sq = inf.readInteger();
    
    string s[4];
    s[0] = ouf.readString();
    string cs1 = ans.readString();
    const string impos = "Impossible";
    if (s[0] == impos) {
      if (cs1 == impos) {
        quitf(_ok, "OK. Impossible");
      } else {
        quitf(_wa, "WRONG ANSWER. Stated impossible, actually possible");
      }
    }
    for (int i = 1; i < 4; ++i) {
      s[i] = ouf.readString();
    }
    for (int i = 0; i < 4; ++i) {
      if (!checkLine(s[i])) {
        quitf(_pe, "Presentation error");
      }
    }
    vector<vector<int> > a(6, vector<int>(6, 0));
    int sq1 = 0;
    int p1 = 0;
    for (int i = 0; i < 4; ++i) {
      for (int j = 0; j < 4; ++j) {
        if (s[i][j] == '*') {
          a[i + 1][j + 1] = 1;
          ++sq1;
        } else {
          a[i + 1][j + 1] = 0;
        }
      }
    }
    if (sq1 != sq) {
      quitf(_wa, "WRONG ANSWER. Wrong size");
    }
    for (int i = 0; i <= 4; ++i) {
      for (int j = 0; j <= 4; ++j) {
        if (a[i][j] + a[i][j + 1] == 1) {
          ++p1;
        }
        if (a[i][j] + a[i + 1][j] == 1) {
          ++p1;
        }
      }
    }
    if (p1 != p) {
      quitf(_wa, "WRONG ANSWER. Wrong perimeter");
    }
    bool done = false;
    for (int i = 0; i <= 4; ++i) {
      for (int j = 0; j <= 4; ++j) {
        if (done) {
          break;
        }
        if (a[i][j]) {
          if (dfs(&a, i, j) != sq) {
            quitf(_wa, "WRONG ANSWER. No connectivity");
          } else {
            done = true;
          }
        }
      }     
    }
    quitf(_ok,"OK");
}
