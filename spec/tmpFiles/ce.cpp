#include<algorithm>
#include<iostream>
#include<cstdio>
#include<cmath>
#include<string>
#include<cstring>
#include<cstdlib>
#include<map>
#include<pair>  //there
#include<vector>
using namespace std;
#define fname1 ""//."
#define fname2 ""//put.txt"
#define maxn 100*1000*2
#define inf 1000*1000*1000
const int dx[4] = {0, 0, -1, 1};
const int dy[4] = {-1, 1, 0, 0};

struct rec{
  int a, b;
};

map <int, map<int, bool> > bridge;
vector <int> a[20500];

int n, m, i, x, y, ans, col, mini, maxi;

int w[20500], l[20500], up[20500], mas[200500];


void dfs(int v, int pr, int h){
  w[v] = 1;
  l[v] = h;
  for (int i = 0; i < a[v].size(); i++)
    if (a[v][i] != pr){
          if (!w[a[v][i]]){
        dfs(a[v][i], v, h + 1);
        up[v] = min(up[v], up[a[v][i]]);
        if (up[a[v][i]] > l[v]){
          mini = min(v, a[v][i]);
          maxi = max(v, a[v][i]);
          bridge[mini][maxi] = true;
        }
      }else
        up[v] = min(up[v], l[a[v][i]]);
  }
}


int main(){
        freopen("k.in", "r", stdi);  //there
        freopen("k.out", "w", stdout);
        scanf("%d%d", &n, &m);
        for (i = 0; i < m; i++){
          scanf("%d%d", &x, &y);
          a[x].push_back(y);
          a[y].push_back(x);
        }
        for (i = 1; i <= n; i++)
            up[i] = 100500;
        for (i = 1; i <= n; i++)
      if (!w[i])
              dfs(i, 0, 1);
        freopen("k.in", "r", stdin);
        scanf("%d%d", &n, &m);
        for (i = 0; i < m; i++){
      scanf("%d%d", &x, &y);
            mini = min(x, y);
            maxi = max(x, y);
          if (bridge[mini][maxi] == true)
              mas[++ans] = i + 1;
        }
        printf("%d\n", ans);
        for (i = 1; i <= ans; i++)
          printf("%d\n", mas[i]);

    return 0;
}