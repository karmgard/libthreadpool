#ifndef __THREADPOOL_H
#define __THREADPOOL_H

#include <pthread.h>
#include <deque>
#include <iostream>
#include <unistd.h>

using namespace std;

class threadpool {
 public:
  threadpool(void);
  threadpool( void fptr(void *), unsigned=2, bool=false );
  ~threadpool( void );

  void start(void);
  void stop(void);
  void set_thread(void fptr(void *));
  void enqueue(void *);
  void *dequeue(pthread_t id);
  void wait_until_empty(void);
  unsigned int get_queue_size(void);
  void dump_queue(unsigned int=0);

  unsigned int get_pool_size(void);
  void set_pool_size( unsigned int );

  void queue_lock(void);
  void queue_unlock(void);

  void increase_pool(unsigned int=1);
  void decrease_pool(unsigned int=1);

  void setVerbose( bool );
  bool getVerbose( void );

  threadpool  operator++(int);
  threadpool  operator--(int);
  threadpool& operator++(void);
  threadpool& operator--(void);

 private:
  pthread_t *tid;
  void (*funcPtr)(void *);

  pthread_mutex_t read_lock, write_lock, wait_lock, print_lock;
  pthread_cond_t  queue_not_empty, queue_is_empty;
  bool queue_empty, shutting_down, verbose, initialized;

  unsigned short thread_id;

  unsigned int poolSize;

  deque<void *> queue;

  inline void fCall( void *p ) {this->funcPtr(p);}

  static void* thread(void* p) {

    threadpool *pool = (threadpool *)p;

    unsigned short id = pool->thread_id++;

    if ( pool->verbose ) {
      pthread_mutex_lock(&pool->print_lock);
      cout << pool << "->" << id << " starting up\n";
      pthread_mutex_unlock(&pool->print_lock);
    }

    while( true ) {
    
      // Ought to block until something is in the queue
      void *ptr = pool->dequeue(id);

      if ( pool->shutting_down )
	break;

      if ( !ptr )
	continue;

      if ( pool->verbose ) {
	pthread_mutex_lock(&pool->print_lock);
	cout << pool << "->" << id << " is taking " << ptr << endl;
	pthread_mutex_unlock(&pool->print_lock);
      }
      pool->funcPtr(ptr);

    }

    if ( pool->verbose ) {
      pthread_mutex_lock(&pool->print_lock);
      cout << pool << "->" << id << " shutting down\n";
      pthread_mutex_unlock(&pool->print_lock);
    }
    return NULL;
  }

};
#endif
