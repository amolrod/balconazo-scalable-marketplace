import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SkeletonList } from './skeleton-list';

describe('SkeletonList', () => {
  let component: SkeletonList;
  let fixture: ComponentFixture<SkeletonList>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SkeletonList]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SkeletonList);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
