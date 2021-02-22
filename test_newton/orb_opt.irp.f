program orb_opt
  implicit none
  
  double precision, allocatable :: grad(:,:),R(:,:)
  double precision, allocatable :: H(:,:),e_val(:),work(:,:)
  double precision, allocatable :: Hm1(:,:),v_grad(:),gHm1(:),A(:,:),vec(:),Hm1_tmpr(:,:)
  integer :: info,method,n,i,j,lwork
  
  double precision :: angle, norm, normH
  
  method = 1
  
  n = mo_num*(mo_num-1)/2
 
  !============
  ! Allocation
  !============
 
  allocate(v_grad(n),R(mo_num,mo_num))
  allocate(H(n,n),Hm1(n,n),gHm1(n),A(mo_num,mo_num))  
  allocate(Hm1_tmpr(n,n))

  !=============
  ! Calculation
  !=============
  
  if (method == 0) then
    
    call gradient(n,v_grad)
    
    print*, 'Norm : ', norm 
    print*, 'v_grad' 
    print*, v_grad(:)

    allocate(grad(mo_num,mo_num))

    call dm_vec_to_mat(v_grad,size(v_grad,1),grad,size(grad,1),info)  
  
    call dm_antisym(grad,mo_num,mo_num,info)
    call dm_rotation(grad,mo_num,R,mo_num,mo_num,info)

    call dm_newton_test(R) 

    deallocate(grad,R)
  
  else 
    
    call gradient(n,v_grad)
    
    norm = norm2(v_grad)
    print*, 'Norm : ', norm
    
    print*, 'grad'
    do i=1,mo_num
        print*, 'v_grad', v_grad(:)
    enddo
    
    !call v2compute_r_orbrot_g
    !v_grad = 0.05d0 * v_grad
    
    call hess(n,H)
    
    !call v2compute_r_orbrot_h
    normH = norm2(H)
    print*, 'NormH : ', normH

    
    lwork=3*n-1
    allocate(work(lwork,n),e_val(n))
    
    call dsyev('V','U',n,H,size(H,1),e_val,work,lwork,info)
    if (info /= 0) then
        call ABORT
    endif
   
    Hm1=0d0 
    do i=1,n
        print*,'H_val',e_val(i)
        if ( (ABS(e_val(i))>1.d-7)) then
            Hm1(i,i)=1d0/e_val(i)
        else
            Hm1(i,i)=0d0
        endif
    enddo
    
    deallocate(work,e_val)
    
    call dgemm('N','T',n,n,n,1d0,Hm1,size(Hm1,1),H,size(H,1),0d0,Hm1_tmpr,size(Hm1_tmpr,1))
    !print*,'Hm1', Hm1_tmpr(:,:) 
    call dgemm('N','N',n,n,n,1d0,H,size(H,1),Hm1_tmpr,size(Hm1_tmpr,1),0d0,Hm1,size(Hm1,1))
    
    !print*,'grad'
    !print*, grad(:,:)
    !print*,'Hm1'
    !print*, Hm1(:,:)
    !print*, 'H'
    !print*, H(:,:)

    !print*,'vgrad',v_grad(:) 
    
    call dgemv('N',n,n,1d0,Hm1,size(Hm1,1),v_grad,1,0d0,gHm1,1)
    
    call dm_vec_to_mat(gHm1,n,A,mo_num,info)
    
    !do i=1,mo_num
    !  do j=1,mo_num
    !    A(i,j) = -0.0017d0!angle
    !  enddo
    !enddo
    
    call dm_antisym(A,mo_num,mo_num,info)
    call dm_rotation(A,mo_num,R,mo_num,mo_num,info)
    
    print*,'R'
    print*,R(:,:)
   
    call dm_newton_test(R)
    
    deallocate(v_grad,H,Hm1,Hm1_tmpr,gHm1,A,R)
 endif

end program
