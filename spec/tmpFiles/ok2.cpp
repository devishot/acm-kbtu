#include <algorithm>
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <cmath>
#include <vector>
#include <set>
#include <map>
using namespace std;

#define sz 1000*1000*10

int n;

int main(){
//freopen("input.txt", "r", stdin);
//freopen("output.txt", "w", stdout);
  scanf("%d", &n);
  int ans = 0;
  for(int i=1, x; i<=n; i++){
    scanf("%d", &x);
    ans += x;
  }
  printf("%d", ans);

  return 0;
}
