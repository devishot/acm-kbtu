#include<algorithm>
#include<iostream>
#include<cstdio>
#include<cmath>
#include<string>
#include<cstring>
#include<cstdlib>
using namespace std;
#define fname1 ""//."
#define fname2 ""//put.txt"
#define sz 100*1000*5
#define inf 1000*1000*1000
int i, n, m, x, y, k, a[sz], e[sz];
int prev[sz], f[sz], len, t, to, q, tin[sz], fup[sz];
bool was[sz], w[sz];

void add(int x, int y){
        len++;
        e[len] = y;
        prev[len] = f[x];
        f[x] = len;
}


void its_cutpoint (int v){
        w[v] = true;
}



void dfs(int v, int p){
        was[v] = true;
        tin[v] = fup[v] = t++;
        int q = f[v];
        int child = 0;
        while (q){
          int to = e[q];
                if (to != p){
                        if (was[to])
                                fup[v] = min (fup[v], tin[to]);
                        else{
                                dfs(to , v);
                                fup[v] = min (fup[v] , fup[to]);
                                if (fup[to] >= tin[v] && p != -1) its_cutpoint(v);
                                ++child;
                        }
                }
        q = prev[q];
        }
        if (p == -1 && child > 1) its_cutpoint(v);
}


int main(){
        freopen("m.in","r",stdin);
        freopen("m.out","w",stdout);
        scanf("%d%d",&n,&m);
        for (i = 1; i <= m; i++){
                scanf("%d%d",&x,&y);
                add(x,y);
                add(y,x);
        }
        for (i = 1; i <= n ; i++)
                if ( !was[i]) dfs(i , -1);
        for (i = 1; i <= n; i++)
                if (w[i]) {k++; a[k] = i;}
        printf("%d\n",k);
        for (i = 1; i <= k; i++)
                printf("%d\n",a[i]);
        return 0;
}